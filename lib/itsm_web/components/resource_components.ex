defmodule ItsmWeb.ResourceComponents do
  use Phoenix.Component

  import ItsmWeb.CoreComponents

  @doc """
  범용 리소스 카드. items는 [%{name, badge, details: [{label, value}]}] 형태.
  리소스 요약이 필요할 경우에는 resource_badge 또는 resource_summary 컴포넌트를 별도로 만들어서 items에 추가하는 형태로 확장
  """
  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :icon_class, :string, default: "text-zinc-500"
  attr :items, :list, required: true

  def resource_card(assigns) do
    ~H"""
    <div class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
      <div class="flex items-center gap-2 mb-4">
        <%!-- <.icon name={@icon} class={["h-5 w-5", @icon_class]} /> --%>
        <.icon name={@icon} class={"h-5 w-5 #{@icon_class}"} />
        <h4 class="font-medium text-zinc-900">{@title}</h4>
      </div>
      
      <%= if Enum.empty?(@items) do %>
        <div class="flex h-32 flex-col items-center justify-center rounded-lg border border-dashed border-zinc-300 bg-zinc-50 text-center text-zinc-500">
          <.icon name="hero-inbox" class="h-6 w-6 text-zinc-300 mb-2" />
          <p class="text-sm">No {String.downcase(@title)} connected.</p>
        </div>
      <% else %>
        <div class="space-y-4">
          <%= for item <- @items do %>
            <div class="rounded-lg border border-zinc-100 bg-zinc-50 p-4">
              <div class="flex items-center justify-between mb-3">
                <span class="font-semibold text-zinc-900">{item.name}</span>
                <span class="inline-flex items-center rounded-md border border-zinc-200 bg-white px-2 py-0.5 text-xs font-medium text-zinc-600 shadow-sm">
                  {item.badge}
                </span>
              </div>
              
              <div class="mt-4 space-y-3 text-sm">
                <%= for {label, value} <- item.details do %>
                  <div class="flex justify-between items-center border-b border-zinc-100 pb-2 last:border-0 last:pb-0">
                    <span class="text-zinc-500">{label}</span>
                    <span class="font-medium text-zinc-900">{value}</span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
