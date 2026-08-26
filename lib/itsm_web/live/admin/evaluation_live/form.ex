defmodule ItsmWeb.Admin.EvaluationLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Evaluations
  alias Itsm.Evaluations.Evaluation

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)
     |> assign_new_options()}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"evaluation" => evaluation_params}, socket) do
    changeset = Evaluations.change_evaluation(socket.assigns.evaluation, evaluation_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"evaluation" => evaluation_params}, socket) do
    save_evaluation(socket, socket.assigns.live_action, evaluation_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    socket
    |> assign(:page_title, "New Evaluation")
    |> assign(:evaluation, %Evaluation{})
    |> assign_new(:form, fn -> to_form(Evaluations.change_evaluation(%Evaluation{})) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    evaluation = Evaluations.get_evaluation!(id)

    socket
    |> assign(:page_title, "Edit Evaluation")
    |> assign(:evaluation, evaluation)
    |> assign_new(:form, fn -> to_form(Evaluations.change_evaluation(evaluation)) end)
    |> Itsm.PubSub.Helper.subscribe(Evaluation, id: id, is_admin: true)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:crew_options, fn -> Itsm.Admin.Crews.get_select_options() end)
  end

  defp save_evaluation(socket, :edit, evaluation_params) do
    %{current_scope: %{user: action_user}, evaluation: evaluation} = socket.assigns

    case Evaluations.update_evaluation(action_user, evaluation, evaluation_params) do
      {:ok, _evaluation} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/evaluations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_evaluation(socket, :new, evaluation_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Evaluations.create_evaluation(action_user, evaluation_params) do
      {:ok, _evaluation} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/evaluations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_evaluation,
         %{id: id},
         %{assigns: %{evaluation: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_evaluation,
         %{id: id},
         %{assigns: %{evaluation: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/evaluations")}
  end
end
