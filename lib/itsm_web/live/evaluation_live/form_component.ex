defmodule ItsmWeb.EvaluationLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Evaluations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage evaluation records in your database.</:subtitle>
      </.header>

      <.simple_form
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
        <:actions>
          <.button phx-disable-with="Saving...">Save Evaluation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{evaluation: evaluation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Evaluations.change_evaluation(evaluation))
     end)}
  end

  @impl true
  def handle_event("validate", %{"evaluation" => evaluation_params}, socket) do
    changeset = Evaluations.change_evaluation(socket.assigns.evaluation, evaluation_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"evaluation" => evaluation_params}, socket) do
    save_evaluation(socket, socket.assigns.action, evaluation_params)
  end

  defp save_evaluation(socket, :edit, evaluation_params) do
    case Evaluations.update_evaluation(socket.assigns.evaluation, evaluation_params) do
      {:ok, evaluation} ->
        notify_parent({:saved, evaluation})

        {:noreply,
         socket
         |> put_flash(:info, "Evaluation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_evaluation(socket, :new, evaluation_params) do
    case Evaluations.create_evaluation(evaluation_params) do
      {:ok, evaluation} ->
        notify_parent({:saved, evaluation})

        {:noreply,
         socket
         |> put_flash(:info, "Evaluation created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
