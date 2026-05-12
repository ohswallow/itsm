defmodule ItsmWeb.CreateCommentDialog do
  use ItsmWeb, :live_component
  alias Itsm.Comments
  alias Itsm.Comments.Comment
  alias Itsm.Approvals

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

  # def handle_event("save", %{"comment" => comment_params}, socket) do
  #   %{request: request, action: action, current_user: user} = socket.assigns

  #   case Comments.create_comment(request, user, comment_params) do
  #     {:ok, _comment} ->
  #       case action do
  #         :approve ->
  #           Service.approve_request(request, user)
  #           # :reject -> Service.reject_request(request, user)
  #       end

  #       {:noreply, push_navigate(socket, to: ~p"/approvals")}

  #     {:error, changeset} ->
  #       {:noreply, assign(socket, form: to_form(changeset))}
  #   end
  # end

  # def handle_event("save", %{"comment" => comment_params}, socket) do
  #   %{request: request, action: action, current_user: user} = socket.assigns

  #   with {:ok, _comment} <- Comments.create_comment(request, user, comment_params),
  #        {:ok, _} <- Service.approve_or_reject_request(request, user, action) do
  #     {:noreply, push_navigate(socket, to: ~p"/approvals")}
  #   else
  #     {:error, _} ->
  #       {:noreply, put_flash(socket, :error, "Failed")}
  #   end
  # end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    %{request: request, action: action, current_user: action_user} = socket.assigns

    with {:ok, _comment} <- Comments.create_comment(action_user, request, comment_params),
         {:ok, _} <- do_action(action, request, action_user) do
      {:noreply,
       socket
       |> clear_flash()
       |> push_patch(to: ~p"/approvals")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "Approval Error")
        {:noreply, put_flash(socket, :error, "Failed")}
    end
  end

  defp do_action(:approve, request, action_user), do: Approvals.approve(request, action_user)
  defp do_action(:reject, request, action_user), do: Approvals.reject(request, action_user)
  # defp perform_action(:approve, request, user) do
  #   Service.approve_or_reject_request(request, user, :approve)
  # end

  # defp perform_action(:reject, request, user) do
  #   Service.approve_or_reject_request(request, user, :reject)
  # end
end
