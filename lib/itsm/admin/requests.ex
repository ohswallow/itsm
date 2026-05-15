defmodule Itsm.Admin.Requests do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Service.Request

  defdelegate get_request!(id), to: Itsm.Requests

  defdelegate change_request(request, attrs \\ %{}), to: Itsm.Requests

  defdelegate create_request(action_user, attrs \\ %{}), to: Itsm.Requests

  defdelegate with_assoc(request, preloads), to: Itsm.Requests

  def update_request(%User{} = action_user, %Request{} = request, attrs) do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, request} ->
        event = :update_request
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, request}, id: request.id)

        {:ok, request}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_request(%User{} = action_user, %{"id" => id}) do
    get_request!(id)
    |> Request.delete_changeset()
    |> Repo.delete()
    |> case do
      {:ok, request} ->
        event = :delete_request
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, request}, id: request.id)

        {:ok, request}

      {:error,
       %Ecto.Changeset{
         errors: [
           id: {message, [constraint: :foreign, constraint_name: "approvals_request_id_fkey"]}
         ]
       }} ->
        {:error, :foreign_approvals, message}
    end
  end
end
