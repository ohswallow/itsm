defmodule ItsmWeb.Admin.CommonCodeLive.Index do
  use ItsmWeb, :live_view

  alias Itsm.Admin.CommonCodes
  alias Itsm.Common.CommonCode
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:common_codes, [])
     |> Itsm.PubSub.Helper.subscribe(CommonCodes, is_admin: true)}
  end

  def handle_params(params, url, socket) do
    {:noreply,
     socket
     |> assign_paged_stream(:common_codes, CommonCode, params, url)
     |> assign(:page_title, gettext("Listing Common codes"))}
  end

  def handle_event("delete", %{"id" => _id} = common_code_params, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
    {:ok, common_code} = CommonCodes.delete_common_code(action_user, common_code_params)

    {:noreply, stream_delete(socket, :common_codes, common_code)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [default_columns: [:group_code, :label, :code]]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      resource_name: gettext("Common Code"),
      target_key: :common_codes,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
