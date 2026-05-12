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
        Itsm.Utils.broadcast(__MODULE__, {action_user, event, request})
        Itsm.Utils.broadcasts(__MODULE__, {action_user, event, request})
        {:ok, request}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_request(%User{} = action_user, %{"id" => id}) do
    Repo.delete(get_request!(id))
    |> case do
      {:ok, request} ->
        event = :delete_request
        Itsm.Utils.broadcast(__MODULE__, {action_user, event, request})
        Itsm.Utils.broadcasts(__MODULE__, {action_user, event, request})
        {:ok, request}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
