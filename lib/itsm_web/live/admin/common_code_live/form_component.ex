defmodule ItsmWeb.Admin.CommonCodeLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.CommonCodes

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{common_code: common_code} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:conflict, false)
     |> assign_new(:form, fn ->
       to_form(CommonCodes.change_common_code(common_code))
     end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage codes records in your database.</:subtitle>
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
        id="codes-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:group_code]} type="text" label={gettext("Group Code")} />
        <.input field={@form[:code]} type="text" label={gettext("Code")} />
        <.input field={@form[:label]} type="text" label={gettext("Label")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input field={@form[:sort_order]} type="number" label={gettext("Sort Order")} />
        <.input field={@form[:is_active]} type="checkbox" label={gettext("Is Active")} />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Codes</.button>
        </:actions>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"common_code" => common_code_params}, socket) do
    changeset = CommonCodes.change_common_code(socket.assigns.common_code, common_code_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"common_code" => common_code_params}, socket) do
    save_common_code(socket, socket.assigns.action, common_code_params)
  end

  defp save_common_code(socket, :edit, common_code_params) do
    %{current_user: action_user} = socket.assigns

    case CommonCodes.update_common_code(
           action_user,
           socket.assigns.common_code,
           common_code_params
         ) do
      {:ok, _common_code} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_common_code(socket, :new, common_code_params) do
    %{current_user: action_user} = socket.assigns

    case CommonCodes.create_common_code(action_user, common_code_params) do
      {:ok, _common_code} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
