defmodule ItsmWeb.Admin.CommonCodeLive.Show do
  use ItsmWeb, :live_view

  alias Itsm.Admin.CommonCodes

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, gettext("Show Common Code"))
     |> assign(:common_code, CommonCodes.get_common_code!(id))
     |> Itsm.PubSub.Helper.subscribe(CommonCodes, id: id, is_admin: true)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp handle_pubsub(
         action_user,
         event,
         %{id: id} = item,
         %{assigns: %{common_code: %{id: id}}} = socket
       ) do
    opts =
      [target_key: :common_code, resource_name: gettext("Common Code")]
      |> push_event_action(event)

    {:noreply,
     socket
     |> ItsmWeb.LiveUtils.handle_standard_pubsub(action_user, event, item, opts)}
  end

  defp handle_pubsub(_user, _event, _item, socket) do
    {:noreply, socket}
  end

  defp push_event_action(opts, :delete_common_code),
    do: Keyword.put(opts, :push_navigate, to: ~p"/admin/common-codes")

  defp push_event_action(opts, _), do: opts
end
