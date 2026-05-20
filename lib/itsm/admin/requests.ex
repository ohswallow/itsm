defmodule Itsm.Admin.Requests do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Service.Request

  defdelegate get_request!(id), to: Itsm.Requests

  defdelegate change_request(request, attrs \\ %{}), to: Itsm.Requests

  def create_request(%User{} = action_user, attrs \\ %{}) do
    action_user
    |> Ecto.build_assoc(:requests)
    |> Request.changeset(attrs)
    |> Ecto.Changeset.put_change(:requestor_name, action_user.display_name)
    |> Repo.insert()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_request, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

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
