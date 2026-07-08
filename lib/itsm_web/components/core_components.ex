defmodule ItsmWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: ItsmWeb.Gettext

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.ColocatedHook

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          
          <p>{msg}</p>
        </div>
         <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://phoenix-html.hexdocs.pm/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
           {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span> <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" /> {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ItsmWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ItsmWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  ################################################################
  # Phoenix Framework 1.8+ 이상부터는 지원하지 않는 컴포넌트(deprecate) 시작
  ################################################################

  @doc """

  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              
              <div id={"#{@id}-content"}>{render_slot(@inner_block)}</div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-10">
      <.link
        navigate={@navigate}
        class="btn-text inline-flex items-center gap-1 hover:text-kb-blue transition-colors"
      >
        <.icon name="hero-arrow-left-mini" class="h-4 w-4" /> {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  ################################################################
  # Phoenix Framework 1.8+ 이상부터는 지원하지 않는 컴포넌트(deprecate) 종료
  ################################################################

  ###############################################################
  # ITSM Custom Compoents  시작
  ##############################################################
  attr :field, Phoenix.HTML.FormField, doc: "@form[:start_date_time]"
  attr :id, :string
  attr :label, :string, default: nil
  attr :default_view_date, :any, default: nil
  attr :default_selected_date_time, :any, default: nil
  attr :show_time, :boolean, default: false
  attr :min, :any, default: nil
  attr :max, :any, default: nil
  attr :disabled_dates, :list, default: []
  attr :errors, :list, default: []
  attr :rest, :global

  attr :rests, :map,
    default: %{
      label: %{},
      container: %{},
      selected_date_time: %{},
      popup: %{},
      grid: %{},
      date: %{},
      hour: %{},
      minute: %{}
    }

  def itsm_calendar(assigns) do
    ~H"""
    <.live_component
      module={ItsmWeb.CalendarComponent}
      {assigns}
      id={assigns[:id] || (assigns[:field] && assigns[:field].id) || "calendar-static-id"}
      label={@label}
      field={@field}
      default_view_date={@default_view_date}
      default_selected_date_time={@default_selected_date_time}
      show_time={@show_time}
      min={@min}
      max={@max}
      disabled_dates={@disabled_dates}
      errors={@errors}
      rests={@rests}
    />
    """
  end

  attr :field, Phoenix.HTML.FormField
  attr :id, :string
  attr :target, :any, default: nil
  attr :label, :string, default: nil
  attr :start_col_class, :any, default: nil
  attr :days, :list, default: [], doc: "[%{disabled: boolean, date: Date, day: integer}]"
  attr :view_date, :any, default: nil
  attr :selected_date_time, :any, default: nil
  attr :show_time, :boolean, default: false
  attr :errors, :list, default: []
  attr :rest, :global

  attr :rests, :map,
    default: %{
      label: %{},
      container: %{},
      selected_date_time: %{},
      popup: %{},
      grid: %{},
      date: %{},
      hour: %{},
      minute: %{}
    }

  def calendar_ui(assigns) do
    ~H"""
    <div
      {@rests[:container]}
      phx-feedback-for={@field[:name]}
      class="relative"
      id={"datepicker-container-#{@id}"}
      data-calendar-root
    >
      <div>
        <div
          :if={assigns[:label]}
          label={@label}
          class="block text-sm font-semibold leading-6 text-zinc-800"
        >
          {@label}
        </div>
        
        <div
          id={"datepicker-input-#{@id}"}
          class="flex items-center border rounded-lg px-3 py-2 cursor-pointer hover:border-indigo-500 bg-white"
          phx-hook="Calendar.Toggle"
          phx-click={
            JS.toggle(to: "##{@id}-calendar-popup")
            |> JS.dispatch("calendar:opened", to: "##{@id}-calendar-popup")
          }
        >
          <input
            id={"selected-date-time-#{@id}"}
            name={@field && @field.name}
            utc-value={@selected_date_time}
            format={if @show_time, do: "datetime", else: "date"}
            class="text-transparent bg-transparent border-none focus:ring-0 focus:outline-none cursor-pointer w-full p-0 absolute inset-0 z-10"
            phx-update="ignore"
            readonly
            value={@selected_date_time}
          />
          <div
            {@rests[:selected_date_time]}
            {@rest}
            id={"display-date-time-#{@id}"}
            class="text-gray-700 pointer-events-none w-full"
            phx-hook="LocalTime.ToLocale"
            utc-value={@selected_date_time}
            format={if @show_time, do: "datetime", else: "date"}
          >
          </div>
           <span class="text-gray-400">📅</span>
        </div>
        
        <.error :for={msg <- @errors}>{msg}</.error>
      </div>
      
      <div
        {@rests[:popup]}
        id={"#{@id}-calendar-popup"}
        class="hidden absolute z-50 mt-2 p-4 bg-white border rounded-xl shadow-xl w-80"
        phx-click-away={JS.hide(to: "##{@id}-calendar-popup")}
      >
        <div class="flex items-center justify-between mb-4">
          <div class="flex gap-1">
            <button
              type="button"
              phx-click="shift"
              phx-value-unit="year"
              phx-value-amount="-1"
              phx-target={@target}
              class="p-1 hover:bg-gray-100 rounded text-gray-400"
            >
              ≪
            </button>
            
            <button
              type="button"
              phx-click="shift"
              phx-value-unit="month"
              phx-value-amount="-1"
              phx-target={@target}
              class="p-1 hover:bg-gray-100 rounded"
            >
              ◀
            </button>
          </div>
          
          <div class="font-bold text-lg">{"#{@view_date.year}년 #{@view_date.month}월"}</div>
          
          <div class="flex gap-1">
            <button
              type="button"
              phx-click="shift"
              phx-value-unit="month"
              phx-value-amount="1"
              phx-target={@target}
              class="p-1 hover:bg-gray-100 rounded"
            >
              ▶
            </button>
            
            <button
              type="button"
              phx-click="shift"
              phx-value-unit="year"
              phx-value-amount="1"
              phx-target={@target}
              class="p-1 hover:bg-gray-100 rounded text-gray-400"
            >
              ≫
            </button>
          </div>
        </div>
        
        <div
          {@rests[:grid]}
          id={"#{@id}-calendar-grid"}
          phx-hook="Calendar.DateGrid"
          phx-target={@target}
          class="grid grid-cols-7 gap-1 text-center"
          utc-value={@selected_date_time}
          format="datetime"
          data-show-time={"#{@show_time}"}
        >
          <div :for={day_name <- ~w(일 월 화 수 목 금 토)} class="text-xs text-gray-400 pb-2">
            {day_name}
          </div>
          
          <div
            :for={{date, index} <- Enum.with_index(@days)}
            {@rests[:date]}
            id={"#{@id}-date-#{date.date}"}
            data-date={date.date}
            data-disabled={date.disabled || nil}
            class={[
              index == 0 && @start_col_class,
              "p-2 text-sm rounded-lg transition-all cursor-pointer hover:bg-gray-100"
            ]}
            phx-update="ignore"
          >
            {date.day}
          </div>
        </div>
        
        <div
          :if={@show_time}
          class="flex items-center justify-center gap-2 mt-4 pt-4 border-t border-gray-100"
        >
          <div class="flex items-center gap-1 bg-gray-50 p-2 rounded-lg border border-gray-200 w-fit">
            <input
              {@rests[:hour]}
              id={"#{@id}-selected-date-time-hour"}
              name={"#{@field.form.name}[calendar_ui][#{@field.name}][hour]"}
              phx-hook="Calendar.Input"
              utc-value={@selected_date_time}
              type="number"
              format="hour"
              min="0"
              max="23"
              phx-target={@target}
              phx-update="ignore"
              class="w-24 bg-transparent text-center font-mono text-lg focus:outline-none focus:text-blue-600"
            /> <span class="text-gray-400 font-bold">:</span>
            <input
              {@rests[:minute]}
              id={"#{@id}-selected-date-time-minute"}
              name={"#{@field.form.name}[calendar_ui][#{@field.name}][minute]"}
              phx-hook="Calendar.Input"
              utc-value={@selected_date_time}
              type="number"
              format="minute"
              min="0"
              max="59"
              phx-target={@target}
              phx-update="ignore"
              class="w-24 bg-transparent text-center font-mono text-lg focus:outline-none focus:text-blue-600"
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, default: "table-static-id"
  attr :results, :map, required: true
  attr :rest, :global
  slot :inner_block, required: true

  def itsm_table_container(assigns) do
    ~H"""
    <.live_component
      module={ItsmWeb.TableContainerComponent}
      {assigns}
      id={assigns[:id] || (assigns[:field] && assigns[:field].id) || "table-static-id"}
      results={@results}
    >
      {render_slot(@inner_block)}
    </.live_component>
    """
  end

  attr :id, :string, default: "table-static-id"
  attr :results, :map, required: true
  attr :rest, :global
  slot :inner_block, required: true
  attr :target, :any, default: nil

  def table_container_ui(assigns) do
    ~H"""
    <div class="filter-section">
      <form
        {@rest}
        phx-change="update-filters"
        phx-target={@target}
      >
        <div
          :if={@results.range_column_options not in [[], [""]]}
          class="grid grid-cols-1 md:grid-cols-12 gap-4 items-end"
        >
          <div class="md:col-span-4">
            <label>조건 날짜</label>
            <.input
              id={"#{@id}-util-filters-range-column"}
              type="select"
              name="range_column"
              options={@results.range_column_options}
              value={@results.params.range_column}
            />
          </div>
          
          <div class="md:col-span-8">
            <label>날짜 범위</label>
            <div class="flex justify-start items-center">
              <.itsm_calendar
                field={
                  %Phoenix.HTML.FormField{
                    id: "start_date",
                    form: %{name: "start_date", params: %{}},
                    name: "start_date",
                    errors: [],
                    field: String.to_atom("start_date"),
                    value: ""
                  }
                }
                default_selected_date_time={@results.params.start_date}
              />
              <div class="mx-1">-</div>
              
              <.itsm_calendar
                field={
                  %Phoenix.HTML.FormField{
                    id: "end_date",
                    form: %{name: "end_date", params: %{}},
                    name: "end_date",
                    errors: [],
                    field: String.to_atom("end_date"),
                    value: ""
                  }
                }
                default_selected_date_time={@results.params.end_date}
              />
            </div>
          </div>
        </div>
        
        <div
          :if={@results.columns_options not in [[], [""], ["전체"]]}
          class="flex justify-between gap-4 items-center"
        >
          <div class="flex-2">
            <label>검색 컬럼 선택</label>
            <.input
              id={"#{@id}-util-filters-search-columns"}
              type="select"
              name="search_columns[]"
              options={@results.columns_options}
              multiple
              size="1"
              phx-hook="InputSelect.selectAll"
              value={@results.params.search_columns}
            />
          </div>
          
          <div class="flex-2">
            <label>검색</label>
            <.input
              type="text"
              name="search"
              placeholder="검색어를 입력해주세요"
              value={@results.params.search}
              phx-debounce="300"
            />
          </div>
          
          <div class="flex-1 w-full">
            <.link patch={@results.current_path}>
              <.icon
                name="hero-arrow-path"
                class="mr-2 h-4 w-4 group-hover:rotate-180 transition-transform duration-500"
              /> <span>초기화</span>
            </.link>
          </div>
        </div>
      </form>
    </div>

    <div class="table-container">{render_slot(@inner_block)}</div>

    <div class="grid grid-cols-3 items-center w-full mt-6">
      <div class="justify-self-start flex items-center">
        <div class="text-sm text-zinc-600">Total: {@results.total_count}</div>
        
        <form phx-change="update-filters" phx-target={@target} class="ml-4">
          <input
            type="number"
            name="page_size"
            value={@results.params.page_size}
            class="w-12 px-2 py-1 text-sm border rounded focus:outline-none focus:ring-1 focus:ring-zinc-400"
            phx-debounce="500"
          />
        </form>
      </div>
      
      <nav class="justify-self-center flex gap-2 items-center">
        <div class="pagination flex items-center">
          <.link
            :if={@results.params.page > 1}
            patch={"#{@results.current_path}?#{Plug.Conn.Query.encode(Map.put(@results.params, :page, @results.params.page - 1))}"}
            class="pagination-item"
          >
            &lt;
          </.link>
          
          <span :if={@results.params.page <= 1} class="pagination-item pagination-item-disabled">
            &lt;
          </span>
          
          <div class="pagination flex items-center">
            <span
              :for={
                page_num <-
                  Enum.uniq([
                    1,
                    @results.params.page - 1,
                    @results.params.page,
                    @results.params.page + 1,
                    @results.total_pages
                  ])
              }
              :if={page_num > 0 and page_num <= @results.total_pages}
              class="flex items-center"
            >
              <span
                :if={
                  page_num == @results.total_pages and @results.params.page < @results.total_pages - 2
                }
                class="pagination-item border-none"
              >
                ...
              </span>
              
              <.link
                patch={"#{@results.current_path}?#{Plug.Conn.Query.encode(Map.put(@results.params, :page, page_num))}"}
                class={[
                  "pagination-item",
                  page_num == @results.params.page && "pagination-item-active"
                ]}
              >
                {page_num}
              </.link>
              
              <span
                :if={page_num == 1 and @results.params.page > 3}
                class="pagination-item border-none"
              >
                ...
              </span>
            </span>
          </div>
          
          <.link
            :if={@results.params.page < @results.total_pages}
            patch={"#{@results.current_path}?#{Plug.Conn.Query.encode(Map.put(@results.params, :page, @results.params.page + 1))}"}
            class="pagination-item"
          >
            &gt;
          </.link>
          
          <span
            :if={@results.params.page >= @results.total_pages}
            class="pagination-item pagination-item-disabled"
          >
            &gt;
          </span>
        </div>
      </nav>
    </div>
    """
  end

  attr :group, :string
  attr :code, :string

  def common_code_label(assigns) do
    ~H"""
    <span data-common-code={"#{@group}:#{@code}"}>{Itsm.CommonCodes.get_label(@group, @code)}</span>
    """
  end

  @doc """
  Renders a time element that displays a localized time using a LiveView hook.
  yyyy.mm.dd hh:mm
  """
  attr :at, :any, required: true, doc: "UTC DateTime struct or ISO string"
  attr :id, :string, required: true

  def local_time(assigns) do
    ~H"""
    <time
      id={@id}
      phx-hook="LocalTime.ToLocaleString"
      datetime={@at}
      class="invisible"
    >
      {@at}
    </time>
    """
  end

  def toggle(js \\ %JS{}, selector) do
    JS.toggle(js,
      to: selector,
      time: 200,
      in:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"},
      out:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  attr :id, :string, required: true
  slot :inner_block, required: true

  def dropdown_menu(assigns) do
    ~H"""
    <div
      id={"dropdown-#{@id}"}
      class="relative"
      phx-window-keydown={hide("#dropdown-#{@id}-body")}
      phx-key="escape"
      phx-click-away={hide("#dropdown-#{@id}-body")}
    >
      <button
        type="button"
        phx-click={toggle("#dropdown-#{@id}-body")}
        class="p-2 hover:bg-gray-100 rounded-full text-gray-500"
      >
        <.icon name="hero-ellipsis-vertical" class="h-6 w-6" />
      </button>
      
      <div
        id={"dropdown-#{@id}-body"}
        class="hidden absolute right-12 bottom-0 w-48 bg-white rounded-lg shadow-lg border border-gray-200 z-10"
      >
        <div class="py-1">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  attr :class, :string, default: nil

  def loading_spinner(assigns) do
    ~H"""
    <div class={["lds-spinner", @class]}>
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
      
      <div></div>
    </div>
    """
  end

  def live_select(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if used_select?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(:errors, Enum.map(errors, &translate_error(&1)))
      |> assign(:live_select_opts, assigns_to_attributes(assigns, [:errors, :label]))

    ~H"""
    <div phx-feedback-for={@field.name}>
      <label for={@field.id}>{@label}</label>
      <LiveSelect.live_select
        field={@field}
        allow_clear={true}
        debounce={300}
        container_class="relative w-full"
        text_input_class="input input-bordered w-full focus:input-primary"
        dropdown_class="absolute z-[100] menu bg-base-100 border border-base-300 w-full rounded-box shadow-xl max-h-60 overflow-y-auto mt-1 p-2"
        option_class="rounded-lg p-2 cursor-pointer hover:bg-base-200"
        active_option_class="bg-primary text-primary-content font-semibold"
        tag_class="flex items-center gap-1 mb-1"
        {@live_select_opts}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Checks whether the live select input has been used (i.e., changed from its initial state).
  defp used_select?(%Phoenix.HTML.FormField{field: field, form: form}) do
    used_param?(form.params, "#{field}_text_input")
  end

  defp used_param?(_params, "_unused_" <> _), do: false

  defp used_param?(params, field) do
    field_str = "#{field}"
    unused_field_str = "_unused_#{field}"

    case params do
      %{^field_str => _, ^unused_field_str => _} ->
        false

      %{^field_str => %{} = nested} when not is_struct(nested) ->
        Enum.any?(Map.keys(nested), &used_param?(nested, &1))

      %{^field_str => _val} ->
        true

      %{} ->
        false
    end
  end

  @doc """
  사용자 검색을 위한 라이브 컴포넌트입니다.
  """
  attr :id, :string, required: true
  attr :current_scope, :any, required: true
  attr :opts, :list, default: [], doc: "{:exclude_crew, Crew.t()} 크루원을 제외하고 검색한다"
  attr :rest, :global

  def users_search(assigns) do
    ~H"""
    <.live_component
      id={@id}
      current_scope={@current_scope}
      opts={@opts}
      module={ItsmWeb.SearchUsersDialog}
    />
    """
  end

  @doc """
  복사 가능한 텍스트를 렌더링하는 컴포넌트입니다.
  """
  attr :value, :string, required: true, doc: "복사할 전체 텍스트"
  attr :label, :string, default: nil, doc: "툴팁 등에 표시할 이름 (예: ID, Email)"

  attr :slice_range, :integer,
    default: 8,
    doc: "화면에 표시할 텍스트의 길이 (기본값: 8, 예: 123e4567-e89b-12d3-a456-426614174000 -> 123e4567...)"

  def copyable_text(assigns) do
    assigns =
      assign_new(assigns, :title, fn ->
        if assigns[:label], do: "Click to copy #{assigns.label}", else: "Click to copy"
      end)

    ~H"""
    <span
      class="font-mono text-blue-600 cursor-pointer hover:text-blue-800 hover:underline"
      title={@title}
      phx-click={JS.dispatch("phx:copy", detail: %{text: @value})}
    >
      {String.slice(@value, 0, @slice_range)}
    </span>
    """
  end

  ###############################################################
  # ITSM Custom Compoents  종료
  ##############################################################

  #################################################################
  # ITSM Custom Compoents Main 이후 추가
  #################################################################

  attr :visible, :boolean, default: true
  attr :state, :atom, default: :default, values: [:default, :error]
  attr :title, :string, default: nil
  attr :body, :string, default: nil
  slot :inner_block

  def card(assigns) do
    assigns =
      assigns
      |> assign_new(:title, fn -> if assigns.state == :error, do: "⚠️ 충돌 발생", else: "" end)
      |> assign_new(:body, fn ->
        if assigns.state == :error, do: "현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.", else: ""
      end)

    ~H"""
    <div
      :if={@visible}
      class={[
        "card border",
        @state == :default && "bg-base-100 text-base-content border-base-200 shadow-sm",
        @state == :error && "bg-error/10 text-error border-error/20 animate-pulse"
      ]}
    >
      <div class="card-body">
        <h2 :if={@title != ""} class="card-title">{@title}</h2>
        
        <p :if={@body != ""}>{@body}</p>
         {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  ###############################################################
  # ITSM Custom Compoents Main 이후 추가 종료
  ##############################################################

  @doc """
  Modal 컴포넌트

  ### Examples

      <.daisy_modal id="my-modal" title="My Modal">
        <p>This is the content of the modal.</p>
      </.daisy_modal>

      Client-side에서 모달을 오픈
      <button phx-click={JS.dispatch("daisy:modal:show", to: "#my-modal")}>Open Modal</button>

      Server-side에서 모달을 오픈
      def handle_event("save", params, socket) do
        {noreply, push_event(socket, "daisy:modal:show", %{id: "my-modal"})}
      end
  """
  attr :id, :string, required: true
  attr :title, :string, default: ""
  slot :inner_block, required: true

  def daisy_modal(assigns) do
    ~H"""
    <dialog id={@id} class="modal" phx-hook=".DaisyModal" phx-update="ignore">
      <div class="modal-box overflow-visible">
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2">✕</button>
        </form>
        
        <h3 class="text-lg font-bold">{@title}</h3>
        
        <p class="py-4">
          {render_slot(@inner_block)}
        </p>
      </div>
    </dialog>

    <script :type={ColocatedHook} name=".DaisyModal">
      export default {
        mounted() {
          // 1. 클라언트(브라우저) 안에서 JS.dipatch()로 호출할때
          this.el.addEventListener("daisy:modal:show", () => {this.el.showModal()});
          this.el.addEventListener("daisy:modal:close", () => {this.el.close()});
          // 2. 서버에서 push_event()로 호출할때
          this.handleEvent("daisy:modal:show", (payload) => {
            if (payload.id === this.el.id) this.el.showModal();
          });
          this.handleEvent("daisy:modal:close", (payload) => {
            if (payload.id === this.el.id) this.el.close();
          });
        }
      }
    </script>
    """
  end
end
