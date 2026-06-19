defmodule ItsmWeb.Admin.AttachmentLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Attachments
  alias Itsm.Attachments.Attachment
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:attachments, []) |> Itsm.PubSub.Helper.subscribe(Attachments)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = attachment_params, socket) do
    %{current_user: action_user} = socket.assigns
    {:ok, attachment} = Attachments.delete_attachment(action_user, attachment_params)

    {:noreply, stream_delete(socket, :attachments, attachment)}
  end

  def handle_event("view_attachment", %{"id" => id, "filename" => filename}, socket) do
    {:noreply, assign(socket, :selected_attachment, %{id: id, filename: filename})}
  end

  def handle_event("close_attachment", _, socket) do
    {:noreply, assign(socket, :selected_attachment, nil)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    socket
    |> assign_paged_stream(:attachments, Attachment, params, url)
    |> assign(:page_title, "Listing Attachments")
    |> assign(:attachment, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Attachment")
    |> assign(:attachment, %Attachment{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Attachment")
    |> assign(:attachment, Attachments.get_attachment!(id))
  end

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [
      default_columns: [
        :filename,
        :local_path,
        :file_type,
        :byte_size,
        :status,
        :resource_type,
        :resource_id,
        :deleted_at
      ]
    ]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Attachment"),
      target_key: :attachments,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
