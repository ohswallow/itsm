defmodule ItsmWeb.Admin.PostLive.Show do
  alias Itsm.Posts.Post
  alias Itsm.Admin.Comments
  alias ItsmWeb.LiveUtils
  alias Itsm.Service
  alias Itsm.Comments.Comment
  use ItsmWeb, :live_view

  import ItsmWeb.CommonKCreateVmLive.Components
  alias Itsm.Admin.Posts

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    post = Posts.get_post!(id) |> Posts.with_assoc([:board, :author])
    attachments = Itsm.Admin.Attachments.list_attachments_by_resource_is_active(post)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, post)
     |> assign(:attachments_count, length(attachments))
     |> stream(:attachments, attachments, reset: true)
     |> assign(:selected_attachment, nil)
     |> stream(:comments, Comments.list_comments_by_resource(post), reset: true)
     |> assign(:form, to_form(Comments.change_comment(%Comment{})))
     |> LiveUtils.allow_uploads()
     |> Itsm.PubSub.Helper.subscribe(Posts, id: id, is_admin: true)
     |> Itsm.PubSub.Helper.subscribe(Comments, is_admin: true)}
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

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"

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
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
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
