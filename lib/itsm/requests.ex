defmodule Itsm.Requests do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Service.Request
  alias Itsm.Service.Category
  alias Itsm.Accounts.User

  def subscribe_request(request_id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "request:#{request_id}")
  end

  def broadcast_request(request_id, message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "request:#{request_id}", message)
  end

  def list_requests do
    Repo.all(Request)
    |> Repo.preload(:category)
  end

  def get_request!(id) do
    Request
    |> Repo.get!(id)
    |> Repo.preload([:category, :attachments])
  end

  def create_request(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:requests)
    |> Request.changeset(attrs)
    |> Ecto.Changeset.put_change(:requestor_name, user.display_name)
    |> Repo.insert()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def change_request(%Request{} = request, attrs \\ %{}) do
    Request.changeset(request, attrs)
  end

  def change_request(%User{} = user, %Category{} = category, %User{} = assignee, attrs \\ %{}) do
    %Request{
      requestor: user,
      requestor_name: user.display_name,
      assignee: assignee,
      assignee_id: assignee.id,
      assignee_name: assignee.display_name,
      category: category
    }
    |> Request.changeset(attrs)
  end

  # TODO: 수정이 필요함
  def update_request(current_user, %Request{requestor_id: requestor_id} = request, attrs)
      when current_user.id == requestor_id do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        broadcast_request(request.id, {:request_updated, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def delete_request(%Request{} = request) do
    Repo.delete(request)
  end
end
