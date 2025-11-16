defmodule ItsmWeb.DelegationLive.FormComponent do
  use ItsmWeb, :live_component

  import LiveSelect
  alias Itsm.Delegations
  alias Itsm.Accounts

  @impl true
  def update(%{delegation: delegation} = assigns, socket) do
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
        <:subtitle>Use this form to manage delegation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="delegation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <input
          type="hidden"
          name="delegation[delegator_name]"
          value={@form[:delegator_name].value}
        />
        <div class="mb-4">
          <label class="mb-2 block text-sm font-semibold leading-6 text-zinc-800">
            Delegator Name
          </label>
          <.live_select
            field={@form[:delegator_id]}
            phx-target={@myself}
            allow_clear={true}
            mode={:single}
            placeholder="사용자 이름을 입력하세요"
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
                  ID: {option.value} | Email: {option.email} | Organization: {option.organization}
                </span>
              </div>
            </:option>
          </.live_select>
        </div>

        <input
          type="hidden"
          name="delegation[delegatee_name]"
          value={@form[:delegatee_name].value}
        />

        <div class="mb-4">
          <label class="mb-2 block text-sm font-semibold leading-6 text-zinc-800">
            Delegatee Name
          </label>
          <.live_select
            field={@form[:delegatee_id]}
            phx-target={@myself}
            allow_clear={true}
            mode={:single}
            placeholder="사용자 이름을 입력하세요"
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
                  ID: {option.value} | Email: {option.email} | Organization: {option.organization}
                </span>
              </div>
            </:option>
          </.live_select>
        </div>

        <%!-- <.input field={@form[:delegator_name]} type="text" label="Delegator name" /> --%>
        <%!-- <.input field={@form[:delegatee_name]} type="text" label="Delegatee name" /> --%>
        <.input field={@form[:start_date]} type="date" label="Start date" />
        <.input field={@form[:end_date]} type="date" label="End date" />
        <.input
          field={@form[:reason]}
          type="select"
          label="Reason"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Delegations.Delegation, :reason)}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Delegation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    IO.inspect(text, label: "Searching for")
    users = Accounts.search_users(%{"q" => text})

    options =
      Enum.map(users, fn user ->
        %{
          label: user.display_name,
          # LiveSelect의 value는 ID(UUID)로 설정
          value: user.id,
          email: user.email,
          organization: user.organization,
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
    IO.inspect(delegation_params, label: "validate event - before")

    delegation_params =
      delegation_params
      |> update_delegator_params()
      |> update_delegatee_params()

    IO.inspect(delegation_params, label: "validate event - after")

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

  defp save_delegation(socket, :edit, delegation_params) do
    case Delegations.update_delegation(socket.assigns.delegation, delegation_params) do
      {:ok, delegation} ->
        notify_parent({:saved, delegation})

        {:noreply,
         socket
         |> put_flash(:info, "Delegation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_delegation(socket, :new, delegation_params) do
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

  defp update_delegator_params(params) do
    if params["delegator_id"] do
      Map.put(params, "delegator_name", params["delegator_id_text_input"])
    else
      Map.put(params, "delegator_name", nil)
    end
  end

  defp update_delegatee_params(params) do
    if params["delegatee_id"] do
      Map.put(params, "delegatee_name", params["delegatee_id_text_input"])
    else
      Map.put(params, "delegatee_name", nil)
    end
  end

  # defp update_delegator_params(delegation_params) do
  #   if delegation_params["delegator_id"] do
  #     delegator_id = delegation_params["delegator_id"]
  #     delegator_name = delegation_params["delegator_id_text_input"]

  #     delegation_params
  #     |> Map.put("delegator_id", delegator_id)
  #     |> Map.put("delegator_name", delegator_name)
  #   else
  #     Map.put(delegation_params, "delegator_name", nil)
  #   end
  # end

  # defp update_delegatee_params(delegation_params) do
  #   if delegation_params["delegatee_id"] do
  #     delegatee_id = delegation_params["delegatee_id"]
  #     delegatee_name = delegation_params["delegatee_id_text_input"]

  #     delegation_params
  #     |> Map.put("delegatee_id", delegatee_id)
  #     |> Map.put("delegatee_name", delegatee_name)
  #   else
  #     Map.put(delegation_params, "delegatee_name", nil)
  #   end
  # end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
