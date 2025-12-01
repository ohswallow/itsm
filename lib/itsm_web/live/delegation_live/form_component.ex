defmodule ItsmWeb.DelegationLive.FormComponent do
  use ItsmWeb, :live_component

  import LiveSelect
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
        <div class="mb-4">
          <label class="mb-2 block text-sm font-semibold leading-6 text-zinc-800">
            {gettext("Delegator name")}
          </label>
          <.live_select
            field={@form[:delegator_id]}
            phx-target={@myself}
            allow_clear={true}
            mode={:single}
            placeholder={gettext("Search by name")}
            container_extra_class="flex-grow"
            dropdown_extra_class="bg-white shadow-lg w-full max-h-60 overflow-y-auto"
            option_extra_class="text-gray-800 border-b border-gray-200 hover:bg-blue-100 py-2 px-4"
            active_option_class="bg-blue-500 text-white"
          >
            <:clear_button>&times;</:clear_button>
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
          
          <.error
            :for={{msg, opts} <- @form[:delegator_id].errors}
            :if={@form.source.action == :insert or Keyword.get(opts, :validation) != :required}
          >
            {translate_error({msg, opts})}
          </.error>
        </div>
        
        <div class="mb-4">
          <label class="mb-2 block text-sm font-semibold leading-6 text-zinc-800">
            {gettext("Delegatee name")}
          </label>
          <.live_select
            field={@form[:delegatee_id]}
            phx-target={@myself}
            allow_clear={true}
            mode={:single}
            placeholder={gettext("Search by name")}
            container_extra_class="flex-grow"
            dropdown_extra_class="bg-white shadow-lg w-full max-h-60 overflow-y-auto"
            option_extra_class="text-gray-800 border-b border-gray-200 hover:bg-blue-100 py-2 px-4"
            active_option_class="bg-blue-500 text-white"
          >
            <:clear_button>&times;</:clear_button>
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
          
          <.error
            :for={{msg, opts} <- @form[:delegatee_id].errors}
            :if={@form.source.action == :insert or Keyword.get(opts, :validation) != :required}
          >
            {translate_error({msg, opts})}
          </.error>
        </div>
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

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    IO.inspect(text, label: "Searching for")

    # ✅ 1. 현재 로그인한 사용자 정보 가져오기
    current_user = socket.assigns.current_user

    # ✅ 2. 검색 조건(Map) 만들기
    # Admin 여부에 따라 검색 조건 다르게 설정
    search_params =
      if current_user.role == :admin do
        # 관리자(Admin)인 경우:
        # 이름 검색어("q")만 보내고, 조직/부서 코드는 보내지 않음 (전체 User 검색)
        %{"q" => text}
      else
        # 일반 사용자(General 등)인 경우:
        # 내 계열사/부서 코드를 함께 보냄 (같은 계열사/부서 내 User 검색)
        %{
          "q" => text,
          "organization_code" => current_user.organization_code,
          "department_code" => current_user.department_code
        }
      end

    # ✅ 3. 수정된 파라미터로 검색 요청
    users = Accounts.search_users(search_params)

    options =
      Enum.map(users, fn user ->
        %{
          label: user.display_name,
          value: user.id,
          email: user.email,
          organization: user.organization,
          department: user.department,
          employee_number: user.employee_number
        }
      end)

    send_update(LiveSelect.Component,
      id: live_select_id,
      options: options
    )

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
    current_user = socket.assigns.current_user

    # 등록자 id 정보 추가
    delegation_params =
      delegation_params
      |> Map.put("created_by_id", current_user.id)

    case Delegations.create_delegation(delegation_params) do
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
