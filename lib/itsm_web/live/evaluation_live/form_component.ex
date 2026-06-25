defmodule ItsmWeb.EvaluationLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Evaluations

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{evaluation: evaluation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:conflict, fn -> false end)
     |> assign_new(:conflict_msg, fn -> nil end)
     |> assign_new(:form, fn ->
       to_form(Evaluations.change_evaluation(evaluation))
     end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage evaluation records in your database.</:subtitle>
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
        id="evaluation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!-- <.input field={@form[:rating]} type="number" label="Rating" step="any" /> --%>
        <fieldset class="fieldset">
          <%!-- <label class="label">Rating</label> --%>
          <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">Rating</label>
          <div
            class="mt-2 flex w-full"
            data-raty
            data-score-name={@form[:rating].name}
            data-score={@form[:rating].value}
            id={@form[:rating].id}
            phx-update="ignore"
          >
          </div>
        </fieldset>
        <.input field={@form[:comment]} type="text" label={gettext("Comment")} />

        <.button :if={!@conflict} phx-disable-with="Saving...">Save Evaluation</.button>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"evaluation" => evaluation_params}, socket) do
    changeset = Evaluations.change_evaluation(socket.assigns.evaluation, evaluation_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"evaluation" => evaluation_params}, socket) do
    save_evaluation(socket, socket.assigns.action, evaluation_params)
  end

  defp save_evaluation(socket, :edit, evaluation_params) do
    %{current_scope: %{user: action_user}, evaluation: evaluation} = socket.assigns

    case Evaluations.update_evaluation(action_user, evaluation, evaluation_params) do
      {:ok, _evaluation} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patcg)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_evaluation(socket, :new, evaluation_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Evaluations.create_evaluation(action_user, evaluation_params) do
      {:ok, _evaluation} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patcg)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
