defmodule ItsmWeb.ItsmComponents do
  use Phoenix.Component
  use Gettext, backend: ItsmWeb.Gettext

  alias Phoenix.LiveView.JS

  import ItsmWeb.CoreComponents,
    only: [icon: 1, hide: 1, label: 1, error: 1, translate_error: 1, input: 1]

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
        <d
          :if={assigns[:label]}
          label={@label}
          class="block text-sm font-semibold leading-6 text-zinc-800"
        >
          {@label}
        </d>
        
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
            id={"selected_date_time-#{@id}"}
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
            id={"display_date_time-#{@id}"}
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
              id={"#{@id}-selected_date_time-hour"}
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
              id={"#{@id}-selected_date_time-minute"}
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
        class="grid grid-cols-1 md:grid-cols-12 gap-4 items-end"
        phx-target={@target}
      >
        <div class="md:col-span-4">
          <label class="form-label">검색 컬럼 선택</label>
          <.input
            id={@id <> "util_filters_search_columns"}
            type="select"
            name="search_columns[]"
            options={@results.columns_options}
            multiple
            size="1"
            phx-hook="InputSelect.selectAll"
            value={@results.params.search_columns}
          />
        </div>
        
        <div class="md:col-span-6">
          <label class="form-label">검색</label>
          <.input
            type="text"
            name="search"
            placeholder="검색어를 입력해주세요"
            value={@results.params.search}
            phx-debounce="300"
          />
        </div>
        
        <div class="md:col-span-2 flex justify-end pb-1">
          <.link
            patch={@results.current_path}
            class="btn-secondary py-2 px-4 text-sm group flex items-center w-full justify-center"
          >
            <.icon
              name="hero-arrow-path"
              class="mr-2 h-4 w-4 group-hover:rotate-180 transition-transform duration-500"
            /> <span>초기화</span>
          </.link>
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

  attr :value, :string, required: true, doc: "복사할 전체 텍스트"
  attr :label, :string, default: nil, doc: "툴팁 등에 표시할 이름 (예: ID, Email)"
  attr :slice_range, :integer, default: 8

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
end
