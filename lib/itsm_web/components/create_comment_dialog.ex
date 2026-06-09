defmodule ItsmWeb.CreateCommentDialog do
  use ItsmWeb, :live_component
  alias Itsm.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Approvals
  alias ItsmWeb.LiveUtils

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Comments.change_comment(%Comment{}))
     end)}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title} Request
        <:subtitle>Add a comment for this approval</:subtitle>
      </.header>
      
      <.simple_form
        for={@form}
        id="approval-comment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:comment]} type="textarea" label="Comment" phx-hook="MaintainHeight" />
        <:actions><.button type="submit">{@title}</.button></:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset = Comments.change_comment(%Comment{}, comment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    approve_or_reject(socket, socket.assigns.action, comment_params)
  end

  defp approve_or_reject(socket, :approve, params) do
    %{request: request, current_user: action_user} = socket.assigns

    case Approvals.approve(request, action_user, comment: params) do
      {:ok, result} ->
        notify_parent({:approve, result})

        {:noreply,
         socket
         |> put_flash(:info, "request approved")
         |> push_patch(to: socket.assigns.patch)}

      {:error, :create_comment, %Ecto.Changeset{} = changeset, _so_far_changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, step, _changeset, _so_far_changeset} ->
        {:noreply, put_flash(socket, :error, LiveUtils.translate_error(step))}
    end
  end

  defp approve_or_reject(socket, :reject, params) do
    %{request: request, current_user: action_user} = socket.assigns

    params = if params["comment"] == "", do: nil, else: params

    case Approvals.reject(request, action_user, comment: params) do
      {:ok, result} ->
        notify_parent({:reject, result})

        {:noreply,
         socket
         |> put_flash(:info, "request rejected")
         |> push_patch(to: socket.assigns.patch)}

      {:error, step, _changeset, _so_far_changeset} ->
        {:noreply, put_flash(socket, :error, LiveUtils.translate_error(step))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
