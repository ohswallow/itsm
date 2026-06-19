defmodule ItsmWeb.Admin.RequestLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.Requests

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{request: request} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:conflict, false)
     |> assign_new(:form, fn ->
       to_form(Requests.change_request(request))
     end)
     |> assign_new_options()}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage request records in your database.</:subtitle>
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
        id="request-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label={gettext("Title")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input field={@form[:env]} type="text" label={gettext("Environment")} />
        <.itsm_calendar
          field={@form[:due_date]}
          label={gettext("Due Date")}
          show_time
          default_selected_date_time={@form[:due_date].value}
        />
        <.input
          field={@form[:category_id]}
          type="select"
          label={gettext("Category")}
          prompt="Choose a value"
          options={@category_options}
        />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Request</.button>
        </:actions>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"request" => request_params}, socket) do
    changeset = Requests.change_request(socket.assigns.request, request_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"request" => request_params}, socket) do
    save_request(socket, socket.assigns.action, request_params)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:category_options, fn ->
      Itsm.Admin.Categories.get_category_options()
    end)
  end

  defp save_request(socket, :edit, request_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Requests.update_request(
           action_user,
           socket.assigns.request,
           request_params
         ) do
      {:ok, _request} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_request(socket, :new, request_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Requests.create_request(action_user, request_params) do
      {:ok, _request} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
