defmodule ItsmWeb.Admin.CommentLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Comments
  alias Itsm.Comments.Comment

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset = Comments.change_comment(%Comment{}, comment_params)

    {:noreply, socket |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    save_comment(socket, socket.assigns.live_action, comment_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, gettext("New Comment"))
    |> assign(:comment, %Comment{})
    |> assign_new(:form, fn -> to_form(Comments.change_comment(%Comment{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    comment = Comments.get_comment!(id)

    socket
    |> assign(:page_title, gettext("Edit Comment"))
    |> assign(:comment, comment)
    |> assign_new(:form, fn -> to_form(Comments.change_comment(comment)) end)
    |> Itsm.PubSub.Helper.subscribe(Comments, id: id, is_admin: true)
  end

  defp save_comment(socket, :edit, comment_params) do
    %{current_scope: %{user: action_user}, comment: comment} = socket.assigns

    case Comments.update_comment(action_user, comment, comment_params) do
      {:ok, _comment} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/comments")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_comment(socket, :new, comment_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Comments.create_comment(action_user, comment_params) do
      {:ok, _comment} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/comments")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_comment,
         %{id: id},
         %{assigns: %{comment: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_comment,
         %{id: id},
         %{assigns: %{comment: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/comments")}
  end
end
