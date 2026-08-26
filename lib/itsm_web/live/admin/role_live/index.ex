defmodule ItsmWeb.Admin.RoleLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Roles
  alias Itsm.Accounts.Role
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok, socket |> stream(:roles, []) |> Itsm.PubSub.Helper.subscribe(Roles, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_paged_stream(:roles, Role, params, url)
     |> assign(:page_title, "Listing Roles")}
  end

  def handle_event("delete", %{"id" => _id} = role_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, role} = Roles.delete_role(action_user, role_params)

    {:noreply, stream_delete(socket, :roles, role)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [default_columns: [:name, :description]]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Role"),
      target_key: :roles,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
