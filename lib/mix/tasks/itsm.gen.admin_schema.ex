defmodule Mix.Tasks.Itsm.Gen.AdminSchema do
  @shortdoc "Generates an Ecto schema and migration file"

  use Mix.Task

  alias Mix.Phoenix.Schema

  @switches [
    migration: :boolean,
    binary_id: :boolean,
    table: :string,
    web: :string,
    context_app: :string,
    prefix: :string,
    repo: :string,
    migration_dir: :string,
    primary_key: :string,
    scope: :string,
    no_scope: :boolean
  ]

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix phx.gen.schema must be invoked from within your *_web application root directory"
      )
    end

    schema = build(args, [])
    paths = Mix.Phoenix.generator_paths()

    prompt_for_conflicts(schema)

    binding = [
      schema: schema,
      primary_key: schema.opts[:primary_key] || :id,
      scope: schema.scope
    ]

    schema
    |> copy_new_files(paths, binding)
    |> print_shell_instructions()
  end

  defp prompt_for_conflicts(schema) do
    schema
    |> files_to_be_generated()
    |> Mix.Phoenix.prompt_for_conflicts()
  end

  @doc false
  def build(args, parent_opts, help \\ __MODULE__) do
    {schema_opts, parsed, _} = OptionParser.parse(args, switches: @switches)
    [schema_name, plural | attrs] = validate_args!(parsed, help)

    opts =
      parent_opts
      |> Keyword.merge(schema_opts)
      |> put_context_app(schema_opts[:context_app])
      |> maybe_update_repo_module()

    Schema.new(schema_name, plural, attrs, opts)
  end

  defp maybe_update_repo_module(opts) do
    if is_nil(opts[:repo]) do
      opts
    else
      Keyword.update!(opts, :repo, &Module.concat([&1]))
    end
  end

  defp put_context_app(opts, nil), do: opts

  defp put_context_app(opts, string) do
    Keyword.put(opts, :context_app, String.to_atom(string))
  end

  @doc false
  def files_to_be_generated(%Schema{} = schema) do
    [{:eex, "schema.ex.eex", schema.file}]
  end

  @doc false
  def copy_new_files(
        %Schema{context_app: ctx_app, repo: repo, opts: opts} = schema,
        paths,
        binding
      ) do
    files = files_to_be_generated(schema)
    Mix.Phoenix.copy_from(paths, "priv/templates/itsm.gen.schema", binding, files)

    if schema.migration? do
      migration_dir =
        cond do
          migration_dir = opts[:migration_dir] ->
            migration_dir

          opts[:repo] ->
            repo_name = repo |> Module.split() |> List.last() |> Macro.underscore()
            Mix.Phoenix.context_app_path(ctx_app, "priv/#{repo_name}/migrations/")

          true ->
            Mix.Phoenix.context_app_path(ctx_app, "priv/repo/migrations/")
        end

      migration_path = Path.join(migration_dir, "#{timestamp()}_create_#{schema.table}.exs")

      Mix.Phoenix.copy_from(paths, "priv/templates/itsm.gen.schema", binding, [
        {:eex, "migration.exs.eex", migration_path}
      ])
    end

    schema
  end

  @doc false
  def print_shell_instructions(%Schema{} = schema) do
    if schema.migration? do
      Mix.shell().info("""

      Remember to update your repository by running migrations:

          $ mix ecto.migrate
      """)
    end
  end

  @doc false
  def validate_args!([schema, plural | _] = args, help) do
    cond do
      not Schema.valid?(schema) ->
        help.raise_with_help(
          "Expected the schema argument, #{inspect(schema)}, to be a valid module name"
        )

      String.contains?(plural, ":") or plural != Phoenix.Naming.underscore(plural) ->
        help.raise_with_help(
          "Expected the plural argument, #{inspect(plural)}, to be all lowercase using snake_case convention"
        )

      true ->
        args
    end
  end

  def validate_args!(_, help) do
    help.raise_with_help("Invalid arguments")
  end

  @doc false
  @spec raise_with_help(String.t()) :: no_return()
  def raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix phx.gen.schema expects both a module name and
    the plural of the generated resource followed by
    any number of attributes:

        mix phx.gen.schema Blog.Post blog_posts title:string
    """)
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)
end
