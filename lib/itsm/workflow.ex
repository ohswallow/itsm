defmodule Itsm.Workflow do
  @moduledoc """
  요청 타입별 상태 머신 정의.

  ## 지원 워크플로우 타입
  - :service_request - 서비스 요청 (7단계)

  ## 사용 예시
      Workflow.steps(:service_request)
      Workflow.button_label(:service_request, request)
      Workflow.transition(:service_request, request, :approve)
  """

  # ==================================================
  # 워크플로우 정의
  # ==================================================

  @workflows %{
    # 서비스 요청: request → check → plan → review → start → finish → verify → closed
    service_request: %{
      steps: [:request, :validation, :assignment, :check, :start, :finish, :confirmation],
      crew_steps: [:assignment, :check, :start, :finish],
      transitions: %{
        validation: %{
          next: :assignment,
          button_label: "Approve",
          status_label: "Under Review",
          action: :approve
        },
        assignment: %{
          next: :check,
          button_label: "Accept",
          status_label: "Pending Accept",
          action: :approve
        },
        check: %{
          next: :start,
          button_label: "Approve",
          status_label: "Under Work Review",
          action: :approve
        },
        start: %{
          next: :finish,
          button_label: "Start Work",
          status_label: "Pending Work",
          action: :approve
        },
        finish: %{
          next: :confirmation,
          button_label: "Finish Work",
          status_label: "In Progress",
          action: :approve
        },
        confirmation: %{
          next: :closed,
          button_label: "Verify",
          status_label: "Pending Verify",
          action: :feedback
        }
      },
      rejectable: [:validation, :assignment, :check],
      labels: %{
        request: "Request",
        validation: "Validation",
        assignment: "Assignment",
        check: "Check",
        start: "Start",
        finish: "Finish",
        confirmation: "Confirmation"
      }
    }

    # TODO: 변경관리 워크플로우
    # change_management: %{
    #   steps: [:request, :assess, :approve, :schedule, :implement, :review, :confirmation],
    #   crew_steps: [:implement, :review],
    #   transitions: %{...},
    #   rejectable: [:assess, :approve, :schedule],
    #   labels: %{...}
    # }

    # TODO: 인시던트 워크플로우
    # incident: %{
    #   steps: [:reported, :assigned, :investigating, :resolved, :verified],
    #   crew_steps: [:implement, :review],
    #   transitions: %{...},
    #   rejectable: [:assigned, :investigating],
    #   labels: %{...}
    # }
  }

  # ==================================================
  # 워크플로우 조회
  # ==================================================

  def get_workflow(workflow_type), do: Map.get(@workflows, workflow_type)

  def steps(workflow_type), do: get_workflow(workflow_type).steps

  def transitions(workflow_type), do: get_workflow(workflow_type).transitions

  def rejectable_statuses(workflow_type), do: get_workflow(workflow_type).rejectable

  def step_label(workflow_type, step) do
    label = get_in(@workflows, [workflow_type, :labels, step]) || Atom.to_string(step)
    Gettext.gettext(ItsmWeb.Gettext, label)
  end

  # ==================================================
  # 상태 조회
  # ==================================================

  def closed?(%{status: :closed}), do: true
  def closed?(_), do: false

  def rejectable?(workflow_type, %{status: status}) do
    status in rejectable_statuses(workflow_type)
  end

  def next_status(workflow_type, %{status: status}) do
    get_in(transitions(workflow_type), [status, :next])
  end

  def action_type(workflow_type, %{status: status}) do
    get_in(transitions(workflow_type), [status, :action])
  end

  def button_label(workflow_type, %{status: status}) do
    case get_in(transitions(workflow_type), [status, :button_label]) do
      nil -> "-"
      label -> Gettext.gettext(ItsmWeb.Gettext, label)
    end
  end

  def status_label(_workflow_type, %{status: :closed}) do
    Gettext.gettext(ItsmWeb.Gettext, "Closed")
  end

  def status_label(workflow_type, %{status: status}) do
    case get_in(transitions(workflow_type), [status, :status_label]) do
      nil -> "-"
      label -> Gettext.gettext(ItsmWeb.Gettext, label)
    end
  end

  # ==================================================
  # status 변경
  # ==================================================

  # reject: 상태 유지 (거부 이력은 Approval에서 관리)
  def transition(_workflow_type, resource, _action = :reject) do
    Ecto.Changeset.change(resource, status: :rejected)
  end

  # approve: 다음 상태로 전이
  def transition(workflow_type, resource, _action = :approve) do
    next = next_status(workflow_type, resource)
    do_transition(workflow_type, resource, resource.status, next)
  end

  # service_request: validation → Assignment (승인 시 담당 Crew 할당 단계로)
  defp do_transition(:service_request, resource, :validation, :assignment) do
    Ecto.Changeset.change(resource, status: :assignment)
  end

  # service_request: finish → verify (요청자에게 검증 요청)
  defp do_transition(:service_request, resource, :finish, :confirmation) do
    Ecto.Changeset.change(resource,
      status: :confirmation
    )
  end

  # service_request: verify → closed (완료, assignee 초기화)
  defp do_transition(:service_request, resource, :confirmation, :closed) do
    Ecto.Changeset.change(resource, status: :closed)
  end

  # 기본 전이: status만 변경
  defp do_transition(_workflow_type, resource, _from, to) do
    Ecto.Changeset.change(resource, status: to)
  end

  # Crew 담당 단계 조회
  def crew_steps(workflow_type), do: get_workflow(workflow_type).crew_steps

  # 해당 단계가 Crew 담당인지 확인
  def crew_step?(workflow_type, step), do: step in crew_steps(workflow_type)
end
