defmodule ItsmWeb.CommonKCreateVmLive.Show do
  use ItsmWeb, :live_view

  import ItsmWeb.Components.WorkflowSidebar
  import ItsmWeb.CommonKCreateVmLive.Components

  alias Itsm.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Requests
  alias ItsmWeb.LiveUtils
  alias Itsm.Service
  alias Itsm.Attachments

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(Comments.change_comment(%Comment{})))
     |> LiveUtils.allow_uploads()}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    request =
      Requests.get_request!(id)
      |> Requests.with_assoc([
        :category,
        requestor_crew: [:users],
        assignee_crew: [:users],
        crew_references: [crew: [:users]]
      ])

    attachments = Attachments.get_list_attachments(request)

    {:noreply,
     socket
     |> assign(:page_title, "Show Request")
     |> assign(:request, request)
     |> assign(:selected_attachment, nil)
     |> assign(:attachments_count, length(attachments))
     |> stream(:attachments, attachments, reset: true)
     |> stream(:comments, Comments.list_comments_by_resource(Requests.get_request!(id)),
       reset: true
     )
     |> Itsm.PubSub.Helper.subscribe(Requests, id: id)
     |> Itsm.PubSub.Helper.subscribe(Attachments)}
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
    %{request: request, current_user: action_user} = socket.assigns

    case Service.create_comment(
           action_user,
           request,
           LiveUtils.build_attachment_consumer(socket),
           comment_params
         ) do
      {:ok, comment} ->
        changeset = Comments.change_comment(%Comment{})
        comment = Comments.with_assoc(comment, :attachments)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> stream_insert(:comments, comment)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(action_user, :delete_attachment = event, item, socket) do
    opts = [resource_name: gettext("attachment"), target_key: :attachments]

    {:noreply,
     socket
     |> assign(:live_action, :index)
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{request: %{id: id}}} = socket
       ) do
    item =
      item
      |> Requests.with_assoc(
        requestor_crew: [:users],
        assignee_crew: [:users],
        crew_references: [crew: [:users]]
      )

    opts =
      [target_key: :request, resource_name: gettext("Request")]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(
         action_user,
         event,
         %Comment{} = item,
         socket
       ) do
    opts =
      [
        target_key: :comments,
        resource_name: gettext("Comment"),
        live_action: :index
      ]
      |> Keyword.merge(push_event_action(socket, event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)
     |> handle_pubsub_comment(Atom.to_string(event), item)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(socket, :delete_request),
    do: [push_navigate: [to: "#{socket.assigns.current_path}"]]

  defp push_event_action(_socket, _), do: []

  defp handle_pubsub_comment(socket, "update" <> _action, item),
    do: stream_insert(socket, :comments, item)

  defp handle_pubsub_comment(socket, "create" <> _action, item),
    do: stream_insert(socket, :comments, item)

  defp handle_pubsub_comment(socket, _other_event, _item), do: socket
end
