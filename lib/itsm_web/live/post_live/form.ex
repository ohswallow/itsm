defmodule ItsmWeb.PostLive.Form do
  use ItsmWeb, :live_view

  import ItsmWeb.LiveUtils, only: [get_sub_field: 4]
  import ItsmWeb.CommonKCreateVmLive.Components

  alias Itsm.Posts
  alias Itsm.Posts.Post

  def mount(%{"board_id" => board_id}, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)
     |> assign(:board_id, board_id)}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    %{assigns: %{current_scope: %{user: action_user}, post: post, selected_board: selected_board}} =
      socket

    post_params = Map.put(post_params, "board_id", selected_board.id)

    changeset =
      Posts.change_post(
        post,
        action_user: action_user,
        attrs: post_params,
        selected_board_metadata: Map.get(selected_board, :metadata, %{})
      )

    {:noreply,
     socket
     |> assign(:selected_board, selected_board)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    %{assigns: %{selected_board: selected_board}} = socket
    post_params = Map.put(post_params, "board_id", selected_board.id)

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

  defp apply_action(socket, :new, %{"board_id" => board_id}, _url) do
    selected_board = Itsm.Boards.get_board!(board_id)

    socket
    |> assign(:page_title, gettext("New Post"))
    |> assign(:post, %Post{})
    |> assign_new(:form, fn -> to_form(Posts.change_post(%Post{})) end)
    |> assign(:selected_board, selected_board)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    post = Posts.get_post!(id)
    selected_board = Itsm.Admin.Boards.get_board!(post.board_id)

    socket
    |> assign(:page_title, gettext("Edit Post"))
    |> assign(:post, post)
    |> assign_new(:form, fn -> to_form(Posts.change_post(post)) end)
    |> assign(:selected_board, selected_board)
    |> Itsm.PubSub.Helper.subscribe(Posts, id: id)
  end

  defp save_post(socket, :edit, post_params, selected_board_metadata) do
    %{assigns: %{current_scope: %{user: action_user}, post: post}} = socket

    case Posts.update_post(
           action_user,
           post,
           post_params,
           selected_board_metadata
         ) do
      {:ok, post} ->
        {:noreply, socket |> push_navigate(to: ~p"/posts?board_id=#{post.board_id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :new, post_params, selected_board_metadata) do
    %{assigns: %{current_scope: %{user: action_user}}} = socket

    case Posts.create_post(action_user, post_params, selected_board_metadata) do
      {:ok, post} ->
        {:noreply, socket |> push_navigate(to: ~p"/posts?board_id=#{post.board_id}")}

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
         %{assigns: %{post: %{id: id, board_id: board_id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/posts?board_id=#{board_id}")}
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{round(bytes / 1024)} KB"
  defp format_file_size(bytes), do: "#{round(bytes / (1024 * 1024))} MB"
end
