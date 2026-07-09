defmodule ItsmWeb.Admin.PostLive.Form do
  use ItsmWeb, :live_view

  import ItsmWeb.LiveUtils, only: [get_sub_field: 4]
  import ItsmWeb.CommonKCreateVmLive.Components

  alias Itsm.Admin.Posts
  alias Itsm.Posts.Post

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.allow_uploads()
     |> assign_new_options()
     |> apply_action(socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    %{current_scope: %{user: action_user}, post: post} = socket.assigns

    selected_board =
      get_effective_board(
        post_params["board_id"],
        Map.get(post, :board_id),
        socket.assigns[:selected_board]
      )

    changeset =
      Posts.change_post(
        post,
        action_user: action_user,
        attrs: post_params,
        selected_board_metadata: Map.get(selected_board, :metadata, %{}),
        call_back: &Itsm.Utils.maybe_put_change(&1, :inserted_at, post_params["inserted_at"])
      )

    {:noreply,
     socket
     |> assign(:selected_board, selected_board)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    selected_board =
      get_effective_board(
        post_params["board_id"],
        Map.get(socket.assigns[:post], :board_id),
        socket.assigns[:selected_board]
      )

    save_post(
      socket,
      socket.assigns.live_action,
      post_params,
      Map.get(selected_board, :metadata, %{})
    )
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_new_options(socket) do
    socket
    |> assign_new(:board_options, fn -> Itsm.Admin.Boards.get_select_options() end)
    |> assign_new(:author_options, fn -> Itsm.Admin.Accounts.get_select_options() end)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
    |> assign_new(:form, fn -> to_form(Posts.change_post(%Post{})) end)
    |> assign(:selected_board, %{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    post = Posts.get_post!(id)
    selected_board = Itsm.Admin.Boards.get_board!(post.board_id)
    attachments = Itsm.Admin.Attachments.list_attachments_by_resource_is_active(post)

    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, post)
    |> assign_new(:form, fn -> to_form(Posts.change_post(post)) end)
    |> assign(:attachments_count, length(attachments))
    |> stream(:form_attachments, attachments, reset: true)
    |> assign(:selected_board, selected_board)
    |> Itsm.PubSub.Helper.subscribe(Posts, id: id, is_admin: true)
  end

  defp save_post(
         %{assigns: %{uploads: %{attachment: %{entries: [_ | _]}}}} = socket,
         action,
         post_params,
         selected_board_metadata
       ) do
    %{current_scope: %{user: action_user}, post: post} = socket.assigns

    case Posts.save_with_attachment(
           action,
           action_user,
           post || %{},
           post_params,
           selected_board_metadata,
           ItsmWeb.LiveUtils.build_attachment_consumer(socket)
         ) do
      {:ok, _post} ->
        {:noreply, socket |> push_navigate(to: "/admin/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :edit, post_params, selected_board_metadata) do
    %{current_scope: %{user: action_user}, post: post} = socket.assigns

    case Posts.update_post(
           action_user,
           post,
           post_params,
           selected_board_metadata
         ) do
      {:ok, _post} ->
        {:noreply, socket |> push_navigate(to: "/admin/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :new, post_params, selected_board_metadata) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Posts.create_post(action_user, post_params, selected_board_metadata) do
      {:ok, _post} ->
        {:noreply, socket |> push_navigate(to: "/admin/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_post,
         %{id: id},
         %{assigns: %{post: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_post,
         %{id: id},
         %{assigns: %{post: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: "/admin/posts")}
  end

  defp get_effective_board(new_id, current_board_id, current_board) do
    cond do
      Itsm.Utils.blank?(new_id) ->
        %{}

      is_nil(current_board) && !Itsm.Utils.blank?(current_board_id) ->
        Itsm.Admin.Boards.get_board!(current_board_id)

      !Itsm.Utils.blank?(new_id) &&
          (is_nil(current_board) || current_board == %{} || new_id != current_board.id) ->
        Itsm.Admin.Boards.get_board!(new_id)

      is_nil(current_board) && !Itsm.Utils.blank?(current_board_id) ->
        Itsm.Admin.Boards.get_board!(current_board_id)

      true ->
        current_board
    end
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"
end
