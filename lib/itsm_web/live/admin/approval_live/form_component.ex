defmodule ItsmWeb.Admin.ApprovalLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.{Approvals, Accounts, Requests}

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{approval: approval} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:conflict, false)
     |> assign_new(:form, fn ->
       to_form(Approvals.change_approval(approval))
     end)
     |> assign_new_options()}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage approval records in your database.</:subtitle>
      </.header>
      
      <div
        :if={@conflict}
        class="p-4 mb-4 bg-red-50 border border-red-200 text-red-800 rounded animate-pulse"
      >
        <div class="flex items-center gap-2 font-bold">
          <span>⚠️ 충돌 발생!</span>
        </div>
        
        <p class="mt-1 text-sm">{@conflict_msg}</p>
        
        <p class="mt-2 text-xs opacity-75">현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.</p>
      </div>
      
      <.form
        for={@form}
        id="approval-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:request_id]}
          type="select"
          label={gettext("Request")}
          options={@request_options}
        />
        <.input
          field={@form[:status]}
          type="select"
          label={gettext("Status")}
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Service.Approval, :status)}
        />
        <.input
          field={@form[:approver_id]}
          type="select"
          label={gettext("Approver")}
          options={@approver_options}
        /> <.input field={@form[:comment]} type="text" label={gettext("Comment")} />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Approval</.button>
        </:actions>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"approval" => approval_params}, socket) do
    changeset = Approvals.change_approval(socket.assigns.approval, approval_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"approval" => approval_params}, socket) do
    save_approval(socket, socket.assigns.action, approval_params)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:approver_options, fn -> Accounts.get_select_options() end)
    |> assign_new(:request_options, fn -> Requests.get_select_options() end)
  end

  defp save_approval(socket, :edit, approval_params) do
    %{current_user: action_user} = socket.assigns

    case Approvals.update_approval(
           action_user,
           socket.assigns.approval,
           approval_params
         ) do
      {:ok, _approval} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
