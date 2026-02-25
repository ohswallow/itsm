defmodule ItsmWeb.CustomComponents do
  use ItsmWeb, :html
  attr :crew, :map, required: true

  def crew_tooltip(assigns) do
    ~H"""
    <div class="relative group cursor-pointer">
      <span class="text-xs font-semibold text-blue-600">{@crew.name}</span>
      <div class="hidden group-hover:block absolute right-0 top-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg p-3 z-20 min-w-[140px]">
        <div class="text-xs text-left text-gray-400 mb-2 font-medium border-b pb-1">
          {@crew.description}
        </div>

        <div class="space-y-1">
          <div :for={member <- @crew.members} class="text-xs text-gray-700">
            {member.user.display_name}
          </div>
        </div>
      </div>
    </div>
    """
  end
end
