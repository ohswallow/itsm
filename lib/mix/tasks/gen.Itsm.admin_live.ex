defmodule Mix.Tasks.Phx.Gen.Itsm.AdminLive do
  @shortdoc "Generates Admin LiveView, templates, and context for a resource"

  use Mix.Task

  alias Mix.Phoenix.{Context, Schema}
  alias Mix.Tasks.Phx.Gen

  # ex) mix phx.gen.itsm.admin_live Attachments Attachment attachments filename:string local_path:string file_type:string byte_size:integer status:string resource_type:string resource_id:uuid deleted_at:utc_datetime
  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix phx.gen.admin_live must be invoked from within your *_web application root directory"
      )
    end

    Mix.Phoenix.ensure_live_view_compat!(__MODULE__)

    {%Context{} = context, %Schema{} = schema} = Gen.Context.build(args)

    assocs_input =
      context.schema.assocs
      |> Enum.map(fn {name, field, _old_module, table} ->
        new_table = if table === :users, do: :accounts, else: table

        module_name =
          new_table
          |> to_string()
          |> String.split("_")
          |> Enum.map_join(&String.capitalize/1)

        assoc_name =
          table |> to_string() |> String.trim_trailing("s") |> Phoenix.Naming.camelize()

        {name, field, "Itsm.Admin.#{module_name}", new_table, "Itsm.#{module_name}.#{assoc_name}"}
      end)

    schema = Map.put(schema, :assocs_input, assocs_input)

    context = %{
      context
      | schema: %{
          context.schema
          | generate?: false,
            migration?: false
        }
    }

    Gen.Context.prompt_for_code_injection(context)

    binding = [context: context, schema: context.schema]
    paths = Mix.Phoenix.generator_paths()

    if context.generate?, do: Gen.Context.copy_new_files(context, paths, binding)

    admin_context = %{
      context
      | module: Module.concat([Itsm.Admin, context.alias]),
        schema: %{
          schema
          | web_path: "admin",
            web_namespace: Admin,
            route_prefix: "/admin" <> schema.route_prefix
        },
        file: Path.join(["lib", "itsm", "admin", "#{context.basename}.ex"]),
        test_file: "test/itsm/admin/#{context.basename}_test.exs",
        test_fixtures_file: "test/support/fixtures/admin/#{context.basename}_fixtures.ex"
    }

    Gen.Context.prompt_for_code_injection(admin_context)

    admin_binding = [
      context: admin_context,
      schema: admin_context.schema,
      inputs: Mix.Tasks.Phx.Gen.Itsm.AdminHtml.inputs(context.schema)
    ]

    admin_context
    |> copy_new_files(admin_binding, paths)
    |> maybe_inject_imports()
    |> print_shell_instructions()
  end

  defp files_to_be_generated(%Context{schema: schema, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    test_prefix = Mix.Phoenix.web_test_path(context_app)
    web_path = to_string(schema.web_path)
    live_subdir = "#{schema.singular}_live"
    web_live = Path.join([web_prefix, "live", web_path, live_subdir])
    test_live = Path.join([test_prefix, "live", web_path])

    [
      {:eex, "show.ex.eex", Path.join(web_live, "show.ex")},
      {:eex, "index.ex.eex", Path.join(web_live, "index.ex")},
      {:eex, "form_component.ex.eex", Path.join(web_live, "form_component.ex")},
      {:eex, "index.html.heex.eex", Path.join(web_live, "index.html.heex")},
      {:eex, "show.html.heex.eex", Path.join(web_live, "show.html.heex")},
      {:eex, "live_test.exs.eex", Path.join(test_live, "#{schema.singular}_live_test.exs")},
      {:new_eex, "core_components.ex.eex",
       Path.join([web_prefix, "components", "core_components.ex"])}
    ]
  end

  defp copy_new_files(%Context{} = context, binding, paths) do
    files = files_to_be_generated(context)

    binding =
      Keyword.merge(binding,
        assigns: %{
          web_namespace: inspect(context.web_module),
          gettext: true
        }
      )

    Mix.Phoenix.copy_from(paths, "priv/templates/phx.gen.itsm.admin_live", binding, files)
    if context.generate?, do: Gen.Context.copy_new_files(context, paths, binding)

    context
  end

  defp maybe_inject_imports(%Context{context_app: ctx_app} = context) do
    web_prefix = Mix.Phoenix.web_path(ctx_app)
    [lib_prefix, web_dir] = Path.split(web_prefix)
    file_path = Path.join(lib_prefix, "#{web_dir}.ex")
    file = File.read!(file_path)
    inject = "import #{inspect(context.web_module)}.CoreComponents"

    if String.contains?(file, inject) do
      :ok
    else
      do_inject_imports(context, file, file_path, inject)
    end

    context
  end

  defp do_inject_imports(context, file, file_path, inject) do
    Mix.shell().info([:green, "* injecting ", :reset, Path.relative_to_cwd(file_path)])

    new_file =
      String.replace(
        file,
        "use Phoenix.Component",
        "use Phoenix.Component\n      #{inject}"
      )

    if file != new_file do
      File.write!(file_path, new_file)
    else
      Mix.shell().info("""

      Could not find use Phoenix.Component in #{file_path}.

      This typically happens because your application was not generated
      with the --live flag:

          mix phx.new my_app --live

      Please make sure LiveView is installed and that #{inspect(context.web_module)}
      defines both `live_view/0` and `live_component/0` functions,
      and that both functions import #{inspect(context.web_module)}.CoreComponents.
      """)
    end
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: ctx_app} = context) do
    prefix = Module.concat(context.web_module, schema.web_namespace)
    web_path = Mix.Phoenix.web_path(ctx_app)

    if schema.web_namespace do
      Mix.shell().info("""

      Add the live routes to your #{schema.web_namespace} :browser scope in #{web_path}/router.ex:

          scope "/#{schema.web_path}", #{inspect(prefix)}, as: :#{schema.web_path} do
            pipe_through :browser
            ...

      #{for line <- live_route_instructions(schema), do: "      #{line}"}
          end
      """)
    else
      Mix.shell().info("""

      Add the live routes to your browser scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

      #{for line <- live_route_instructions(schema), do: "    #{line}"}
      """)
    end

    if context.generate?, do: Gen.Context.print_shell_instructions(context)
    maybe_print_upgrade_info()
  end

  defp maybe_print_upgrade_info do
    unless Code.ensure_loaded?(Phoenix.LiveView.JS) do
      Mix.shell().info("""

      You must update :phoenix_live_view to v0.18 or later and
      :phoenix_live_dashboard to v0.7 or later to use the features
      in this generator.
      """)
    end
  end

  defp live_route_instructions(schema) do
    [
      ~s|live "/#{schema.plural}", Admin.#{inspect(schema.alias)}Live.Index, :index\n|,
      ~s|live "/#{schema.plural}/new", Admin.#{inspect(schema.alias)}Live.Index, :new\n|,
      ~s|live "/#{schema.plural}/:id/edit", Admin.#{inspect(schema.alias)}Live.Index, :edit\n\n|,
      ~s|live "/#{schema.plural}/:id", Admin.#{inspect(schema.alias)}Live.Show, :show\n|,
      ~s|live "/#{schema.plural}/:id/show/edit", Admin.#{inspect(schema.alias)}Live.Show, :edit|
    ]
  end
end
