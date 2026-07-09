defmodule ItsmWeb.Admin.CategoryLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Categories
  alias Itsm.Service.Category

  alias Itsm.Admin.Crews
  alias Itsm.Admin.CommonCodes

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)
     |> assign_new_options()}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset = Categories.change_category(%Category{}, category_params)

    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.live_action, category_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:assignee_crews_options, fn -> Crews.get_select_options() end)
    |> assign_new(:affiliate_options, fn -> CommonCodes.get_select_options("계열사") end)
    |> assign_new(:region_type_options, fn -> CommonCodes.get_select_options("지역_유형") end)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, gettext("New Category"))
    |> assign(:category, %Category{})
    |> assign_new(:form, fn -> to_form(Categories.change_category(%Category{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    category = Categories.get_category!(id)

    socket
    |> assign(:page_title, gettext("Edit Category"))
    |> assign(:category, category)
    |> assign_new(:form, fn -> to_form(Categories.change_category(category)) end)
    |> Itsm.PubSub.Helper.subscribe(Categories, id: id, is_admin: true)
  end

  defp save_category(socket, :edit, category_params) do
    %{current_scope: %{user: action_user}, category: category} = socket.assigns

    case Categories.update_category(action_user, category, category_params) do
      {:ok, _category} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/categories")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_category(socket, :new, category_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Categories.create_category(action_user, category_params) do
      {:ok, _category} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/categories")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_category,
         %{id: id},
         %{assigns: %{category: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_category,
         %{id: id},
         %{assigns: %{category: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/categories")}
  end
end
