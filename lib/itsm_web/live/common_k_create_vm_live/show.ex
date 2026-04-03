defmodule ItsmWeb.CommonKCreateVmLive.Show do
  use ItsmWeb, :live_view

  import ItsmWeb.Components.WorkflowSidebar
  import ItsmWeb.CommonKCreateVmLive.Components

  alias Itsm.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Requests
  alias Itsm.Service.Request
  alias ItsmWeb.LiveUtils
  alias Itsm.Service

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(Comments.change_comment(%Comment{})))
     |> LiveUtils.allow_uploads()}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    if(connected?(socket)) do
      Itsm.Utils.subscribe(Request, id)
      Itsm.Utils.subscribes(Request)
    end

    {:noreply,
     socket
     |> assign(:page_title, "Show Request")
     |> assign(:request, Requests.get_request!(id))
     |> assign(:selected_attachment, nil)
     |> stream(:comments, Comments.list_comments(Requests.get_request!(id)))}
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
    %{request: request, current_user: current_user} = socket.assigns

    case Service.create_comment(
           request,
           current_user,
           fn -> LiveUtils.consume_attachments(socket) end,
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_info({:pubsub, {user, event, item}}, socket) do
    handle_pubsub(user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(
         user,
         event,
         %{id: id} = item,
         %{assigns: %{request: %{id: id}}} = socket
       ) do
    opts =
      [context_key: :request, resource_name: gettext("Request")]
      |> Keyword.merge(push_event_action(event))

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(:delete_request),
    do: [push_navigate: [to: ~p"/requests"]]

  defp push_event_action(_), do: []
end
