defmodule Itsm.Admin.Requests do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Service.Request

  def get_request!(id), do: Request |> Repo.get!(id)

  def change_request(%Request{} = request, attrs \\ %{}),
    do: Request.admin_changeset(request, attrs)

  def create_request(%User{} = action_user, attrs) do
    action_user
    |> Ecto.build_assoc(:requests)
    |> Request.admin_changeset(attrs)
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

  def with_assoc(%Request{} = request, preloads), do: Repo.preload(request, preloads)

  def update_request(%User{} = action_user, %Request{} = request, attrs) do
    request
    |> Request.admin_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, request} ->
        request = request |> Repo.preload(:category)

        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_request, request},
          id: request.id
        )

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

  def get_select_options do
    Request
    |> select([r], {r.title, r.id})
    |> Repo.all()
  end
end
