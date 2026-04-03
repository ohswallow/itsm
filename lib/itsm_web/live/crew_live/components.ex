defmodule ItsmWeb.CrewLive.Components do
  use ItsmWeb, :live_component

  def filter_form(assigns) do
    ~H"""
    <div class="filter-section">
      <.form
        for={@form}
        class="grid grid-cols-1 md:grid-cols-12 gap-6 items-end"
        id="filter-form"
        phx-change="filter"
      >
        <div class="md:col-span-5">
          <.input
            field={@form[:keyword]}
            placeholder="Search..."
            autocomplete="off"
            phx-debounce="300"
          />
        </div>

        <div class="md:col-span-3">
          <.input
            type="select"
            field={@form[:organization_code]}
            prompt="계열사"
            options={@org_options}
          />
        </div>

        <div class="md:col-span-2 flex justify-end pb-1">
          <.link
            patch={~p"/crews/all"}
            class="btn-secondary py-2 px-4 text-sm group flex items-center w-full justify-center"
          >
            <.icon
              name="hero-arrow-path"
              class="mr-2 h-4 w-4 group-hover:rotate-180 transition-transform duration-500"
            /> <span>초기화</span>
          </.link>
        </div>
      </.form>
    </div>
    """
  end
end
