defmodule Mix.Tasks.Itsm.Gen.AdminHtml do
  @shortdoc "Generates context and controller for an HTML resource"

  use Mix.Task

  alias Mix.Phoenix.Context
  alias Mix.Tasks.Itsm.Gen

  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix itsm.gen.admin_html must be invoked from within your *_web application root directory"
      )
    end

    Mix.Phoenix.ensure_live_view_compat!(__MODULE__)

    {context, schema} = Gen.AdminContext.build(args)
    Gen.AdminContext.prompt_for_code_injection(context)

    binding = [context: context, schema: schema, inputs: inputs(schema)]
    paths = Mix.Phoenix.generator_paths()

    prompt_for_conflicts(context)

    context
    |> copy_new_files(paths, binding)
    |> print_shell_instructions()
  end

  defp prompt_for_conflicts(context) do
    context
    |> files_to_be_generated()
    |> Kernel.++(context_files(context))
    |> Mix.Phoenix.prompt_for_conflicts()
  end

  defp context_files(%Context{generate?: true} = context) do
    Gen.AdminContext.files_to_be_generated(context)
  end

  defp context_files(%Context{generate?: false}) do
    []
  end

  @doc false
  def files_to_be_generated(%Context{schema: schema, context_app: context_app}) do
    singular = schema.singular
    web_prefix = Mix.Phoenix.web_path(context_app)
    web_path = to_string(schema.web_path)
    controller_pre = Path.join([web_prefix, "controllers", web_path])

    [
      {:eex, "controller.ex", Path.join([controller_pre, "#{singular}_controller.ex"])},
      {:eex, "edit.html.heex", Path.join([controller_pre, "#{singular}_html", "edit.html.heex"])},
      {:eex, "index.html.heex",
       Path.join([controller_pre, "#{singular}_html", "index.html.heex"])},
      {:eex, "new.html.heex", Path.join([controller_pre, "#{singular}_html", "new.html.heex"])},
      {:eex, "show.html.heex", Path.join([controller_pre, "#{singular}_html", "show.html.heex"])},
      {:eex, "resource_form.html.heex",
       Path.join([controller_pre, "#{singular}_html", "#{singular}_form.html.heex"])},
      {:eex, "html.ex", Path.join([controller_pre, "#{singular}_html.ex"])}
    ]
  end

  @doc false
  def copy_new_files(%Context{} = context, paths, binding) do
    files = files_to_be_generated(context)
    Mix.Phoenix.copy_from(paths, "priv/templates/itsm.gen.admin_html", binding, files)
    if context.generate?, do: Gen.AdminContext.copy_new_files(context, paths, binding)
    context
  end

  @doc false
  def print_shell_instructions(%Context{schema: schema, context_app: ctx_app} = context) do
    if schema.web_namespace do
      Mix.shell().info("""

      Add the resource to your #{schema.web_namespace} :browser scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

          scope "/#{schema.web_path}", #{inspect(Module.concat(context.web_module, schema.web_namespace))}, as: :#{schema.web_path} do
            pipe_through :browser
            ...
            resources "/#{schema.plural}", #{inspect(schema.alias)}Controller
          end
      """)
    else
      Mix.shell().info("""

      Add the resource to your browser scope in #{Mix.Phoenix.web_path(ctx_app)}/router.ex:

          resources "/#{schema.plural}", #{inspect(schema.alias)}Controller
      """)
    end

    if context.generate?, do: Gen.AdminContext.print_shell_instructions(context)
  end

  @doc false
  def inputs(schema) do
    input_attrs = schema |> render_input_attrs()
    input_assocs = schema |> render_input_assocs()

    input_attrs ++ input_assocs
  end

  defp render_input_attrs(schema) do
    schema.attrs
    |> Enum.map(fn
      {key, :map} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="textarea" label=#{label(key, " (JSON)")}   />)

      {key, :integer} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="number" label=#{label(key)} />)

      {key, :float} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="number" label=#{label(key)} step="any" />)

      {key, :decimal} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="number" label=#{label(key)} step="any" />)

      {key, :boolean} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="checkbox" label=#{label(key)} />)

      {key, :text} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="text" label=#{label(key)} />)

      {key, :date} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="date" label=#{label(key)} />)

      {key, :time} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="time" label=#{label(key)} />)

      {key, :utc_datetime} ->
        ~s(<.itsm_calendar
  field={@form[#{inspect(key)}]}
  label=#{label(key)}
  show_time
  default_selected_date_time={@form[#{inspect(key)}].value}
/>)

      {key, :naive_datetime} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="datetime-local" label=#{label(key)} />)

      {key, {:array, _} = type} ->
        ~s"""
        <.input
          field={@form[#{inspect(key)}]}
          type="select"
          multiple
          label=#{label(key)}
          options={#{inspect(default_options(type))}}
        />
        """

      {key, {:enum, _}} ->
        ~s"""
        <.input
          field={@form[#{inspect(key)}]}
          type="select"
          label=#{label(key)}
          prompt="Choose a value"
          options={Ecto.Enum.values(#{inspect(schema.module)}, #{inspect(key)})}
        />
        """

      {key, _} ->
        ~s(<.input field={@form[#{inspect(key)}]} type="text" label=#{label(key)} />)
    end)
  end

  defp render_input_assocs(schema) do
    schema.assocs
    |> Enum.map(fn {field, fk, _module, _table} ->
      ~s"""
      <.input
        field={@form[#{inspect(fk)}]}
        type="select"
        label=#{label(field)}
        prompt="선택해주세요"
        options={@#{Atom.to_string(field) <> "_options"}}
      />
      """
    end)
  end

  defp default_options({:array, :string}),
    do: Enum.map([1, 2], &{"Option #{&1}", "option#{&1}"})

  defp default_options({:array, :integer}),
    do: Enum.map([1, 2], &{"#{&1}", &1})

  defp default_options({:array, _}), do: []

  defp label(key) do
    humanized = ItsmWeb.LiveUtils.titleize(key)
    "{gettext(\"#{humanized}\")}"
  end

  defp label(key, add) do
    humanized = ItsmWeb.LiveUtils.titleize(key)
    "{gettext(\"#{humanized}\") <> \"#{add}\"}"
  end

  @doc false
  def indent_inputs(inputs, column_padding) do
    columns = String.duplicate(" ", column_padding)

    inputs
    |> Enum.map(fn input ->
      lines = input |> String.split("\n") |> Enum.reject(&(&1 == ""))

      case lines do
        [] ->
          []

        [line] ->
          [columns, line]

        [first_line | rest] ->
          rest = Enum.map_join(rest, "\n", &(columns <> &1))
          [columns, first_line, "\n", rest]
      end
    end)
    |> Enum.intersperse("\n")
  end
end
