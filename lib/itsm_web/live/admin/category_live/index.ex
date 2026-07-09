defmodule ItsmWeb.Admin.CategoryLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Categories
  alias Itsm.Service.Category
  alias Itsm.Paging
  alias Itsm.Admin.CommonCodes

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:categories, [])
     |> assign_new_options()
     |> assign(:page_title, gettext("테스트"))
     |> Itsm.PubSub.Helper.subscribe(Categories, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = category_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, category} = Categories.delete_category(action_user, category_params)

    {:noreply, stream_delete(socket, :categories, category)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:affiliate_options, fn -> CommonCodes.get_select_options("계열사") end)
    |> assign_new(:group_options, fn -> CommonCodes.get_select_options("지역_유형") end)
  end

  defp apply_action(socket, :index, params, url) do
    socket
    |> assign_paged_stream(:categories, Category, params, url)
    |> assign(:page_title, gettext("Listing Categories"))
  end

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [default_columns: [:name, :description, :group, :affiliate, :request_name, :category]]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Category"),
      target_key: :categories,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
