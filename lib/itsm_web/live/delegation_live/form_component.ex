defmodule ItsmWeb.DelegationLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Delegations
  alias Itsm.Accounts
  alias Itsm.CommonCodes

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{delegation: delegation} = assigns, socket) do
    # 새 delegation이면 start_date를 오늘로 기본 설정
    delegation =
      if is_nil(delegation.id) and is_nil(delegation.start_date) do
        %{delegation | start_date: Date.utc_today()}
      else
        delegation
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:conflict, fn -> false end)
     |> assign_new(:conflict_msg, fn -> nil end)
     |> assign_new(:form, fn ->
       to_form(Delegations.change_delegation(delegation))
     end)
     |> assign_new_options()}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>
          {gettext("Use this form to manage delegation records in your database.")}
        </:subtitle>
      </.header>

      <.card
        visible={@conflict}
        state={:error}
        title="⚠️ 충돌 발생!"
      >
        <p>{@conflict_msg}</p>
        <p>현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.</p>
      </.card>

      <.form
        for={@form}
        id="delegation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.live_select
          field={@form[:delegator_id]}
          phx-target={@myself}
          label={gettext("Delegator name")}
          placeholder={gettext("Search by name")}
        >
          <:option :let={option}>
            <%!-- 이름 외 옵션 표출 --%>
            <div class="flex flex-col">
              <span class="font-bold">{option.label}</span>
              <span class="text-sm text-gray-600">
                ID: {option.value} | Email: {option.email} | Organization: {option.organization} | Department: {option.department}
              </span>
            </div>
          </:option>
        </.live_select>

        <.live_select
          field={@form[:delegatee_id]}
          label={gettext("Delegatee name")}
          phx-target={@myself}
          placeholder={gettext("Search by name")}
        >
          <:option :let={option}>
            <%!-- 이름 외 옵션 표출 --%>
            <div class="flex flex-col">
              <span class="font-bold">{option.label}</span>
              <span class="text-sm text-gray-600">
                ID: {option.value} | Email: {option.email} | Organization: {option.organization} | Department: {option.department}
              </span>
            </div>
          </:option>
        </.live_select>

        <.itsm_calendar
          id="start_date_calendar"
          field={@form[:start_date]}
          label={gettext("Start date")}
          min={Date.utc_today()}
        />
        <.itsm_calendar
          id="end_date_calendar"
          field={@form[:end_date]}
          label={gettext("End date")}
          min={Date.utc_today()}
        />
        <.input
          field={@form[:reason]}
          type="select"
          label={gettext("Reason")}
          prompt="Choose a value"
          options={@reason_options}
        />

        <.button :if={!@conflict} phx-disable-with="Saving...">Save Delegation</.button>
      </.form>
    </div>
    """
  end

  def handle_event("live_select_change", %{"text" => keyword, "id" => live_select_id}, socket) do
    %{current_scope: %{user: current_user}} = socket.assigns

    # 본인 선택이 가능한 화면에서 호출 시
    options =
      Accounts.live_select_by_name(current_user, keyword)

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  def handle_event("validate", %{"delegation" => delegation_params}, socket) do
    changeset =
      socket.assigns.delegation
      |> Delegations.change_delegation(delegation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"delegation" => delegation_params}, socket) do
    save_delegation(socket, socket.assigns.action, delegation_params)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:reason_options, fn -> CommonCodes.get_select_options("사유") end)
  end

  defp save_delegation(socket, :new, delegation_params) do
    %{current_scope: %{user: action_user}} = socket.assigns
    %{"delegator_id" => delegator_id, "delegatee_id" => delegatee_id} = delegation_params

    delegator = Accounts.get_user!(delegator_id)
    delegatee = Accounts.get_user!(delegatee_id)

    correct_delegation_params =
      Map.new(delegation_params, fn {k, v} ->
        if k == "start_date" || k == "end_date" do
          {:ok, dt, _} = DateTime.from_iso8601(v)
          new_val = dt |> DateTime.add(9, :hour) |> DateTime.to_iso8601()
          {k, new_val}
        else
          {k, v}
        end
      end)

    case Delegations.create_delegation(
           action_user,
           delegator,
           delegatee,
           correct_delegation_params
         ) do
      {:ok, _delegation} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
