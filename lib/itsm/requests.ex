defmodule Itsm.Requests do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Service.Request
  alias Itsm.Service.Category
  alias Itsm.Accounts.User

  # ==================================================
  # PubSub
  # ==================================================

  def subscribe_request(request_id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "request:#{request_id}")
  end

  def broadcast_request(request_id, message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "request:#{request_id}", message)
  end

  # ==================================================
  # 조회
  # ==================================================

  def get_request!(id) do
    Request
    |> Repo.get!(id)
    |> Repo.preload([
      :category,
      :attachments,
      assignee_crew: [members: :user],
      requestor_crew: [members: :user],
      references: :crew
    ])
  end

  def list_requests do
    Request
    |> Repo.all()
    |> Repo.preload(:category)
  end

  # ==================================================
  # Changeset
  # ==================================================

  def change_request(%Request{} = request, request_params \\ %{}) do
    Request.changeset(request, request_params)
  end

  def change_request(%User{} = user, %Category{} = category, request_params) do
    %Request{
      requestor: user,
      requestor_name: user.display_name,
      assignee_crew_id: category.assignee_crew_id,
      category: category,
      status: :validation
    }
    |> Request.changeset(request_params)
  end

  # ==================================================
  # CUD
  # ==================================================

  def create_request(%User{} = user, request_params \\ %{}) do
    user
    |> Ecto.build_assoc(:requests)
    |> Request.changeset(request_params)
    |> Ecto.Changeset.put_change(:requestor_name, user.display_name)
    |> Repo.insert()
    |> case do
      {:ok, request} -> {:ok, Repo.preload(request, :category)}
      {:error, _} = error -> error
    end
  end

  def update_request(
        %User{id: user_id},
        %Request{requestor_id: user_id} = request,
        request_params
      ) do
    request
    |> Request.changeset(request_params)
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
