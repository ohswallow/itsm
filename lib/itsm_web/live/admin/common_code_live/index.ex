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
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("delete", %{"id" => _id} = common_code_params, socket) do
    %{current_user: action_user} = socket.assigns
    {:ok, common_code} = CommonCodes.delete_common_code(action_user, common_code_params)

    {:noreply, stream_delete(socket, :common_codes, common_code)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    opts = [default_columns: [:group_code, :label, :code]]

    value =
      CommonCode
      |> Paging.search_and_pagination(params, url, opts)

    socket
    |> assign(:results, value.results)
    |> stream(:common_codes, value.entries, reset: true)
    |> assign(:page_title, "Listing Common codes")
    |> assign(:common_code, nil)
  end

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Common Code")
    |> assign(:common_code, %CommonCode{})
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    socket
    |> assign(:page_title, "Edit Common Code")
    |> assign(:common_code, CommonCodes.get_common_code!(id))
  end

  defp handle_pubsub(action_user, event, item, socket) do
    opts = [
      context_key: :common_code,
      resource_name: gettext("Common Code"),
      stream_name: :common_codes,
      push_patch: [to: "#{socket.assigns.current_path}"]
    ]

    {:noreply, socket |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end
end
