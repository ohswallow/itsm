defmodule ItsmWeb.Components.WorkflowSidebar do
  @moduledoc """
  워크플로우 진행 상태 사이드바 LiveComponent.

  ## 사용 예시
      <.live_component
        module={ItsmWeb.Components.WorkflowSidebar}
        id="workflow-sidebar"
        workflow_type={:service_request}
        resource={@request}
      />
  """

  use ItsmWeb, :live_component
  use Gettext, backend: ItsmWeb.Gettext
  import ItsmWeb.CoreComponents

  alias Itsm.Workflow
  alias Itsm.Approvals
  import ItsmWeb.CustomComponents

  @impl true
  def update(assigns, socket) do
    step_data = build_step_data(assigns.workflow_type, assigns.resource)
    {:ok, assign(socket, assigns) |> assign(:step_data, step_data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-64 flex-shrink-0">
      <div class="sticky top-4 bg-white rounded-xl shadow-lg border border-gray-100 p-5">
        <div class="text-center mb-5 pb-4 border-b border-gray-100">
          <label>WorkFlow</label>
        </div>
        
        <div class="space-y-3">
          <.workflow_step
            :for={step <- @step_data}
            step={step}
            resource={@resource}
            workflow_type={@workflow_type}
          />
        </div>
      </div>
    </div>
    """
  end

  # ==================================================
  # Private Components
  # ==================================================
  attr :step, :map, required: true
  attr :resource, :map, required: true
  attr :workflow_type, :atom, required: true

  defp workflow_step(assigns) do
    ~H"""
    <div class={step_container_class(@step.status)}>
      <div class="flex items-center gap-3">
        <div class={step_icon_class(@step.status)}>
          <%= cond do %>
            <% @step.status == :done -> %>
              <.icon name="hero-check" class="w-4 h-4" />
            <% @step.status == :denied -> %>
              <.icon name="hero-x-mark" class="w-4 h-4" />
            <% true -> %>
              {@step.index + 1}
          <% end %>
        </div>
        
        <div><span class={step_label_class(@step.status)}>{@step.label}</span></div>
      </div>
      
      <div class="text-right">
        <.step_detail step={@step} resource={@resource} workflow_type={@workflow_type} />
      </div>
    </div>
    """
  end

  # 1. Workflow Step인 경우 요청자 정보와 생성 일시를 표시
  defp step_detail(%{step: %{index: 0}} = assigns) do
    ~H"""
    <div class="text-xs font-medium text-green-700">{@resource.requestor_name}</div>

    <div
      id={"approval-#{@step.status}-date-#{@resource.requestor_id}"}
      class="text-xs text-green-500"
      phx-hook="LocalTime.ToLocale"
      format="MM/DD HH:mm"
      utc-value={@resource.inserted_at}
    />
    """
  end

  # 2. 완료된 단계 - 승인자 정보 표시
  defp step_detail(%{step: %{status: :done}} = assigns) do
    ~H"""
    <div class="text-xs font-medium text-green-700">{@step.approval.approver_name}</div>

    <div
      id={"approval-#{@step.approval.status}-date-#{@step.approval.id}"}
      class="text-xs text-green-500"
      phx-hook="LocalTime.ToLocale"
      format="MM/DD HH:mm"
      utc-value={@step.approval.inserted_at}
    />
    """
  end

  # 3. :validation 단계 - 요청자 Crew
  defp step_detail(
         %{step: %{status: :active, step: :validation}, resource: %{requestor_crew: crew}} =
           assigns
       )
       when not is_nil(crew) do
    ~H"""
    <.crew_tooltip crew={@resource.requestor_crew} />
    """
  end

  # 4. :assignment, :check, :start, :finish - 담당 Crew
  defp step_detail(
         %{step: %{status: :active, step: step}, resource: %{assignee_crew: crew}} = assigns
       )
       when step in [:assignment, :check, :start, :finish] and not is_nil(crew) do
    ~H"""
    <.crew_tooltip crew={@resource.assignee_crew} />
    """
  end

  # 5. :confirmation 단계 - 요청자
  defp step_detail(
         %{step: %{status: :active, step: :confirmation}, resource: %{requestor_name: name}} =
           assigns
       )
       when not is_nil(name) do
    ~H"""
    <div class="text-xs font-semibold text-blue-600">{@resource.requestor_name}</div>
    """
  end

  # 6. rejected 단계 - 거부한 승인자 정보 표시
  defp step_detail(%{step: %{status: :denied, approval: approval}} = assigns)
       when not is_nil(approval) do
    ~H"""
    <div class="text-xs font-medium text-red-700">{@step.approval.approver_name}</div>

    <div
      id={"approval-#{@step.status}-date-#{@step.approval.id}"}
      class="text-xs text-red-500"
      phx-hook="LocalTime.ToLocale"
      format="MM/DD HH:mm"
      utc-value={@step.approval.inserted_at}
    />
    """
  end

  # 7. :active 외 pending 단계
  defp step_detail(assigns) do
    ~H"""
    <span class="text-xs text-gray-400">-</span>
    """
  end

  defp load_approvals_by_status(request_id) do
    request_id
    |> Approvals.list_approvals_by_request()
    |> Map.new(&{&1.status, &1})
  end

  defp build_step_data(workflow_type, resource) do
    approvals_by_status = load_approvals_by_status(resource.id)

    workflow_type
    |> Workflow.steps()
    |> Enum.with_index()
    |> Enum.map(fn {step, index} ->
      approval = Map.get(approvals_by_status, step)

      status =
        cond do
          step == resource.status -> :active
          approval && approval.action == :reject -> :denied
          index == 0 || (approval && approval.action == :approve) -> :done
          true -> :waiting
        end

      %{
        step: step,
        index: index,
        status: status,
        label: Workflow.step_label(workflow_type, step),
        approval: approval
      }
    end)
  end

  # ==================================================
  # Style Classes (UI 스타일 클래스)
  # done : 완료 작업
  # active   : 진행 하려는 작업
  # waiting   : 대기 중인 작업 (아직 시작되지 않음)
  # denied   : 거부된 작업
  # ==================================================

  defp step_container_class(:done),
    do: "flex items-center justify-between px-3 py-2.5 rounded-lg bg-green-50"

  defp step_container_class(:active),
    do: "flex items-center justify-between px-3 py-3 rounded-lg bg-blue-50 border border-blue-300"

  defp step_container_class(:waiting),
    do: "flex items-center justify-between px-3 py-2.5 rounded-lg opacity-40"

  defp step_container_class(:denied),
    do: "flex items-center justify-between px-3 py-2.5 rounded-lg bg-red-50 min-h-[60px]"

  defp step_icon_class(:denied),
    do:
      "w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold bg-red-500 text-white"

  defp step_icon_class(:done),
    do:
      "w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold bg-green-500 text-white"

  defp step_icon_class(:active),
    do:
      "w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold bg-blue-500 text-white"

  defp step_icon_class(:waiting),
    do:
      "w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold bg-gray-300 text-gray-500"

  defp step_label_class(:denied), do: "text-sm font-medium text-red-700"
  defp step_label_class(:done), do: "text-sm font-medium text-green-700"
  defp step_label_class(:active), do: "text-sm font-semibold text-blue-700"
  defp step_label_class(:waiting), do: "text-sm font-medium text-gray-500"
end
