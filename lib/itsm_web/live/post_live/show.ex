defmodule ItsmWeb.PostLive.Show do
  alias Itsm.Posts.Post
  alias Itsm.Service
  alias ItsmWeb.LiveUtils
  alias Itsm.Comments.Comment
  alias Itsm.Comments
  use ItsmWeb, :live_view

  import ItsmWeb.CommonKCreateVmLive.Components
  alias Itsm.Posts

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id, "board_id" => board_id}, _, socket)
      when board_id != nil and board_id != "" and is_binary(board_id) and
             byte_size(board_id) == 36 do
    target_board = Itsm.Boards.get_board!(board_id)
    post = Posts.get_post!(id) |> Posts.with_assoc([:board, :author])
    attachments = Itsm.Attachments.get_list_attachments(post)

    {:noreply,
     socket
     |> assign(:page_title, gettext("Show Post"))
     |> assign(:post, post)
     |> assign(:attachments_count, length(attachments))
     |> stream(:attachments, attachments, reset: true)
     |> assign(:selected_attachment, nil)
     |> assign(:board_name, Map.get(target_board, :name, ""))
     |> assign(:board_id, Map.get(target_board, :id, ""))
     |> stream(:comments, Comments.list_comments_by_resource(post), reset: true)
     |> assign(:form, to_form(Comments.change_comment(%Comment{})))
     |> LiveUtils.allow_uploads()
     |> Itsm.PubSub.Helper.subscribe(Posts, id: id)
     |> Itsm.PubSub.Helper.subscribe(Comments)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, push_navigate(socket, to: ~p"/boards")}
  end

  def handle_event("view_attachment", %{"id" => id, "filename" => filename}, socket) do
    {:noreply, assign(socket, :selected_attachment, %{id: id, filename: filename})}
  end

  def handle_event("close_attachment", _, socket) do
    {:noreply, assign(socket, :selected_attachment, nil)}
  end

  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset = Comments.change_comment(%Comment{}, comment_params)
    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    %{post: post, current_scope: %{user: action_user}} = socket.assigns

    case Service.create_comment(
           action_user,
           post,
           LiveUtils.build_attachment_consumer(socket),
           comment_params
         ) do
      {:ok, comment} ->
        changeset = Comments.change_comment(%Comment{})

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> stream_insert(:comments, comment)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(
         action_user,
         event,
         %Post{id: id} = item,
         %{assigns: %{post: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :post, resource_name: gettext("Post")]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(
         action_user,
         event,
         %Comment{resource_id: id} = item,
         %{assigns: %{post: %{id: id}}} = socket
       ) do
    opts =
      [
        target_key: :comments,
        resource_name: gettext("Comment"),
        live_action: :index
      ]
      |> Keyword.merge(push_event_action(socket, event))

    item = item |> Comments.with_assoc([:attachments])

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)
     |> handle_pubsub_comment(Atom.to_string(event), item)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(socket, :delete_post),
    do: [push_navigate: [to: "#{socket.assigns.current_path}"]]

  defp push_event_action(_socket, _), do: []

  defp handle_pubsub_comment(socket, "update" <> _action, item),
    do: stream_insert(socket, :comments, item)

  defp handle_pubsub_comment(socket, "create" <> _action, item),
    do: stream_insert(socket, :comments, item)

  defp handle_pubsub_comment(socket, _other_event, _item), do: socket
end
