defmodule ItsmWeb.Admin.RequestLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Requests
  alias Itsm.Service.Request

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset = Requests.change_request(%Request{}, request_params)

    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.live_action, request_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:category_options, fn -> Itsm.Admin.Categories.get_category_options() end)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Request")
    |> assign(:request, %Request{})
    |> assign_new(:form, fn -> to_form(Requests.change_request(%Request{})) end)
    |> assign_new_options()
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    request = Requests.get_request!(id)

    socket
    |> assign(:page_title, "Edit Request")
    |> assign(:request, request)
    |> assign_new(:form, fn -> to_form(Requests.change_request(request)) end)
    |> Itsm.PubSub.Helper.subscribe(Requests, id: id, is_admin: true)
    |> assign_new_options()
  end

  defp save_request(socket, :edit, request_params) do
    %{current_scope: %{user: action_user}, request: request} = socket.assigns

    case Requests.update_request(action_user, request, request_params) do
      {:ok, _request} ->
        {:noreply, socket |> push_navigate(to: "/admin/requests")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, request_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Requests.create_request(action_user, request_params) do
      {:ok, _request} ->
        {:noreply, socket |> push_navigate(to: "/admin/requests")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_request,
         %{id: id},
         %{assigns: %{request: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_request,
         %{id: id},
         %{assigns: %{request: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: "/admin/requests")}
  end
end
