defmodule ItsmWeb.Admin.CategoryLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Categories
  alias Itsm.Service.Category
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Itsm.Utils.subscribes(Category)

    {:ok, socket |> stream(:categories, []) |> assign_new_options()}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => _id} = category_params, socket) do
    {:ok, category} = Categories.delete_category(category_params)

    {:noreply, stream_delete(socket, :categories, category)}
  end

  @impl true
  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  @impl true
  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:affiliate_options, fn -> Itsm.CommonCodes.get_select_options("계열사") end)
    |> assign_new(:group_options, fn -> Itsm.CommonCodes.get_select_options("지역_유형") end)
  end

  defp apply_action(socket, :index, params, url) do
    value =
      Paging.search_and_pagination(params, url, Category, [
        :name,
        :description,
        :group,
        :affiliate,
        :request_name,
        :category
      ])

    socket
    |> assign(:results, value.results)
    |> stream(:categories, value.entries, reset: true)
    |> assign(:page_title, "Listing Categories")
    |> assign(:category, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Category")
    |> assign(:category, %Category{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Category")
    |> assign(:category, Categories.get_category!(id))
  end

  defp handle_pubsub(user, event, item, socket) do
    opts = [
      context_key: :category,
      resource_name: gettext("Category"),
      stream_name: :categories,
      push_patch: [to: ~p"/admin/categories?#{socket.assigns[:results][:params] || %{}}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end
end
