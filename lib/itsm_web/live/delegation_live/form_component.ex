defmodule ItsmWeb.DelegationLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Delegations
  alias Itsm.Accounts

  @impl true
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
     |> assign_new(:form, fn ->
       to_form(Delegations.change_delegation(delegation))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>
          {gettext("Use this form to manage delegation records in your database.")}
        </:subtitle>
      </.header>
      
      <.simple_form
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
         <.input field={@form[:start_date]} type="date" label={gettext("Start date")} />
        <.input field={@form[:end_date]} type="date" label={gettext("End date")} />
        <.input
          field={@form[:reason]}
          type="select"
          label={gettext("Reason")}
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Delegations.Delegation, :reason)}
        />
        <:actions><.button phx-disable-with="Saving...">Save Delegation</.button></:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("live_select_change", %{"text" => keyword, "id" => live_select_id}, socket) do
    IO.inspect(keyword, label: "Searching for")

    %{current_user: current_user} = socket.assigns

    # 본인 선택이 가능한 화면에서 호출 시
    options =
      Accounts.search_user_options(current_user, %{"keyword" => keyword, "include_self" => true})

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"delegation" => delegation_params}, socket) do
    changeset =
      socket.assigns.delegation
      |> Delegations.change_delegation(delegation_params)
      |> Map.put(:action, :validate)

    IO.inspect(changeset.changes, label: "validate event - changeset changes")

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"delegation" => delegation_params}, socket) do
    IO.inspect(delegation_params, label: "Saving delegation with params")
    save_delegation(socket, socket.assigns.action, delegation_params)
  end

  defp save_delegation(socket, :new, delegation_params) do
    %{current_user: current_user} = socket.assigns
    %{"delegator_id" => delegator_id, "delegatee_id" => delegatee_id} = delegation_params

    delegator = Accounts.get_user!(delegator_id)
    delegatee = Accounts.get_user!(delegatee_id)

    case Delegations.create_delegation(current_user, delegator, delegatee, delegation_params) do
      {:ok, delegation} ->
        notify_parent({:saved, delegation})

        {:noreply,
         socket
         |> put_flash(:info, "Delegation created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
