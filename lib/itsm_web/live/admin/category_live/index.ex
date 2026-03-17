defmodule ItsmWeb.Admin.CategoryLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Service.Category
  alias Itsm.Admin.Categories
  alias Itsm.Paging

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:categories, []) |> assign_new_options()}
  end

  @impl true
  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Categories.get_category!(id)
    {:ok, _} = Categories.delete_category(category)

    {:noreply, stream_delete(socket, :categories, category)}
  end

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
end
