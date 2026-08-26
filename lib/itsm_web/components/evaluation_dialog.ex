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
        <div class="rating rating-lg">
          <%= for i <- 1..5 do %>
            <input type="radio" name={@form[:rating].name} value={i} class="mask mask-star bg-orange-400" checked={@form[:rating].value == i}/>
          <% end %>
        </div>
        <p :for={msg <- Enum.map(@form[:rating].errors, &ItsmWeb.CoreComponents.translate_error(&1))} class="mt-1.5 flex gap-2 items-center text-sm text-error">
          <.icon name="hero-exclamation-circle" class="size-5" /> {msg}
        </p>
        <.input field={@form[:comment]} type="textarea" label="Comment" phx-hook="MaintainHeight" />
        <.button phx-disable-with="Saving...">Save Evaluation</.button>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"evaluation" => evaluation_params}, socket) do
    evaluation_params = Map.put(evaluation_params, "crew_id", socket.assigns.crew_id)

    changeset = Evaluations.change_evaluation(%Evaluation{}, evaluation_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"evaluation" => evaluation_params}, socket) do
    %{current_scope: %{user: action_user}} = socket.assigns
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
