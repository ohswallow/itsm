defmodule ItsmWeb.ApprovalLive.Components do
  use ItsmWeb, :live_component

  alias Itsm.Workflow
  alias Itsm.Service.Request

  def action_cell(assigns) do
    assigns = assign(assigns, :action_info, get_action_info(assigns.request))

    ~H"""
    <%= case @action_info do %>
      <% :closed -> %>
        <span class="text-gray-400">closed</span>
      <% {:feedback, label} -> %>
        <.link
          patch={~p"/approvals/#{@request.id}/feedback"}
          class="text-green-600 font-bold hover:underline"
        >
          {label}
        </.link>
      <% {:approve, label, true} -> %>
        <.link
          patch={~p"/approvals/#{@request.id}/approve"}
          class="text-blue-600 hover:underline font-bold"
        >
          {label}
        </.link>
        <.link
          patch={~p"/approvals/#{@request.id}/reject"}
          class="text-red-600 ml-2 hover:underline"
        >
          반려
        </.link>
      <% {:approve, label, false} -> %>
        <.link
          patch={~p"/approvals/#{@request.id}/approve"}
          class="text-indigo-600 font-bold hover:underline"
        >
          {label}
        </.link>
    <% end %>
    """
  end

  defp get_action_info(%Request{} = request) do
    cond do
      Workflow.closed?(request) ->
        :closed

      Workflow.action_type(:service_request, request) == :feedback ->
        {:feedback, Workflow.button_label(:service_request, request)}

      true ->
        {:approve, Workflow.button_label(:service_request, request),
         Workflow.rejectable?(:service_request, request)}
    end
  end
end
