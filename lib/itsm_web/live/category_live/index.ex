defmodule ItsmWeb.CategoryLive.Index do
  use ItsmWeb, :live_view

  import ItsmWeb.CategoryLive.Components

  alias Itsm.Categories
  alias Itsm.CommonCodes

  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Categories)

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> stream(:categories, Categories.filter_categories(params), reset: true)
     |> assign(:current_params, params)
     |> assign(:filtered_category_groups, Categories.get_category_groups(params))
     |> assign(:group_select_options, [{"그룹", ""}] ++ CommonCodes.get_select_options("지역_유형"))
     |> assign(:form, to_form(params))}
  end

  def handle_event("filter", params, socket) do
    params =
      params
      |> Map.take(~w(keyword group sort_by))
      |> Map.reject(fn {_, v} -> v == "" end)

    socket = push_patch(socket, to: ~p"/categories?#{params}")

    {:noreply, socket}
  end

  def handle_info({:pusbusb, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :category,
      resource_name: gettext("Category"),
      stream_name: :categories,
      push_patch: [to: ~p"/categories?#{socket.assigns[:current_params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
