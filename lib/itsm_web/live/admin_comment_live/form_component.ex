defmodule ItsmWeb.AdminCommentLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Comments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage comment records in your database.</:subtitle>
      </.header>
      
      <.simple_form
        for={@form}
        id="comment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:comment]} type="text" label="Comment" />
        <:actions><.button phx-disable-with="Saving...">Save Comment</.button></:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{comment: comment} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Comments.change_comment(comment))
     end)}
  end

  @impl true
  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset = Comments.change_comment(socket.assigns.comment, comment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  # def handle_event("save", %{"comment" => comment_params}, socket) do
  #   save_comment(socket, socket.assigns.action, comment_params)
  # end

  # defp save_comment(socket, :edit, comment_params) do
  #   case Comments.update_comment(socket.assigns.comment, comment_params) do
  #     {:ok, comment} ->
  #       notify_parent({:saved, comment})

  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Comment updated successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, form: to_form(changeset))}
  #   end
  # end

  # defp save_comment(socket, :new, comment_params) do
  #   case Comments.create_comment(comment_params) do
  #     {:ok, comment} ->
  #       notify_parent({:saved, comment})

  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "Comment created successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, form: to_form(changeset))}
  #   end
  # end

  # defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
