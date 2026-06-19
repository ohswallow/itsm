defmodule ItsmWeb.EvaluationDialog do
  use ItsmWeb, :live_component

  alias Itsm.Evaluations
  alias Itsm.Evaluations.Evaluation
  alias Itsm.Approvals

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Evaluations.change_evaluation(%Evaluation{crew_id: assigns.crew_id}))
     end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage evaluation records in your database.</:subtitle>
      </.header>
      
      <.form
        for={@form}
        id="evaluation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!-- <input type="hidden" name={@form[:crew_id].name} value={@crew_id} /> --%>
        <%!-- <.input field={@form[:rating]} type="number" label="Rating" step="any" /> --%>
        <fieldset class="fieldset">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">Rating</label>
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
         <.input field={@form[:comment]} type="textarea" label="Comment" phx-hook="MaintainHeight" />
        <:actions><.button phx-disable-with="Saving...">Save Evaluation</.button></:actions>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"evaluation" => evaluation_params}, socket) do
    evaluation_params = Map.put(evaluation_params, "crew_id", socket.assigns.crew_id)

    changeset = Evaluations.change_evaluation(%Evaluation{}, evaluation_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  # def handle_event("save", %{"evaluation" => evaluation_params}, socket) do
  #   evaluation_params = Map.put(evaluation_params, "crew_id", socket.assigns.crew_id)

  #   case Evaluations.create_evaluation(evaluation_params) do
  #     {:ok, evaluation} ->
  #       notify_parent({:saved, evaluation})

  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Evaluation created successfully")
  #        |> push_navigate(to: ~p"/approvals")}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, form: to_form(changeset))}
  #   end
  # end

  def handle_event("save", %{"evaluation" => evaluation_params}, socket) do
    %{current_user: action_user} = socket.assigns
    evaluation_params = Map.put(evaluation_params, "crew_id", socket.assigns.crew_id)

    case Evaluations.create_evaluation(action_user, evaluation_params) do
      {:ok, evaluation} ->
        %{request: request} = socket.assigns

        case Approvals.approve(request, action_user) do
          {:ok, _request} ->
            notify_parent({:saved, evaluation})

            {:noreply,
             socket
             |> put_flash(:info, "Evaluation created and request approved successfully")
             |> push_navigate(to: ~p"/approvals")}

          {:error, reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Evaluation saved but approval failed: #{inspect(reason)}")}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
