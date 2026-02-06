defmodule ItsmWeb.ItsmComponents do
  use Phoenix.Component
  use Gettext, backend: ItsmWeb.Gettext

  alias Phoenix.LiveView.JS
  import ItsmWeb.CoreComponents, only: [icon: 1, hide: 1, label: 1, error: 1, translate_error: 1]

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
      phx-hook="LocalTime"
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
      <%!--
         [수정된 부분]
         1. left-0 -> right-0 (오른쪽 정렬)
         2. top-12 -> mt-2 w-32 (버튼 바로 아래 위치, 너비 조정)
         3. z-index 확실하게 (z-50)
      --%>
      <div
        id={"dropdown-#{@id}-body"}
        class="hidden absolute left-0 top-12 w-48 bg-white rounded-lg shadow-lg border border-gray-200 z-10"
      >
        <%!-- <div
        id={"dropdown-#{@id}-body"}
        class="hidden absolute right-0 mt-2 w-32 bg-white rounded-lg shadow-lg border border-gray-200 z-50"
      > --%>
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
      <.label for={@field.id}>{@label}</.label>
      
      <LiveSelect.live_select
        field={@field}
        allow_clear={true}
        debounce={300}
        text_input_class="form-input"
        container_extra_class="flex-grow"
        dropdown_extra_class="bg-white shadow-xl border border-kb-border-gray rounded-md w-full max-h-60 overflow-y-auto z-50"
        option_extra_class="text-kb-dark-gray border-b border-gray-50 hover:bg-kb-yellow/20 py-2.5 px-4 transition-colors cursor-pointer"
        active_option_class="bg-kb-yellow text-kb-dark-gray font-bold"
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
end
