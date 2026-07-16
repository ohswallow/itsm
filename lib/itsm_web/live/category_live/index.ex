defmodule ItsmWeb.CategoryLive.Index do
  use ItsmWeb, :live_view

  import ItsmWeb.CategoryLive.Components

  alias Itsm.Categories
  alias Itsm.CommonCodes

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Service Request"))
     |> Itsm.PubSub.Helper.subscribe(Categories)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    categories = Categories.filter_categories(params)

    {:noreply,
     socket
     |> assign(:current_params, params)
     |> assign(:grouped_categories, Enum.group_by(categories, & &1.group))
     |> assign(:category_count, length(categories))
     |> assign(
       :group_select_options,
       CommonCodes.get_select_options("지역_유형")
     )
     |> assign(:form, to_form(params, as: :filter))}
  end

  @impl true
  def handle_event("filter", %{"filter" => params}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/categories?#{normalize_filter_params(params)}"
     )}
  end

  @impl true
  def handle_info({:pubsub, {_action_user, _event, _item}}, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.current_path)}
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp normalize_filter_params(params) do
    params
    |> Map.take(~w(keyword group sort_by))
    |> Map.update("keyword", nil, &String.trim/1)
    |> Map.reject(fn
      {_key, nil} -> true
      {_key, ""} -> true
      {_key, []} -> true
      _ -> false
    end)
  end
end
