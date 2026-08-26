defmodule ItsmWeb.Admin.PermissionLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Permissions
  alias Itsm.Accounts.Permission
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:permissions, [])
     |> Itsm.PubSub.Helper.subscribe(Permissions, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_paged_stream(:permissions, Permission, params, url)
     |> assign(:page_title, "Listing Permissions")}
  end

  def handle_event("delete", %{"id" => _id} = permission_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, permission} = Permissions.delete_permission(action_user, permission_params)

    {:noreply, stream_delete(socket, :permissions, permission)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [default_columns: [:action, role: :name], preloads: [role: :name]]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Permission"),
      target_key: :permissions,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
