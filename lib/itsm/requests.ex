defmodule Itsm.Requests do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Service.Request
  alias Itsm.Service.Category
  alias Itsm.Accounts.User

  # ==================================================
  # 조회
  # ==================================================

  def get_request!(id) do
    Request
    |> Repo.get!(id)
    |> Repo.preload([
      :category,
      :attachments,
      assignee_crew: [:users],
      requestor_crew: [:users],
      references: [crew: [:users]]
    ])
  end

  def list_requests do
    Request
    |> Repo.all()
    |> Repo.preload(:category)
  end

  def with_assoc(%Request{} = request, preloads) when is_list(preloads) do
    Repo.preload(request, preloads)
  end

  # ==================================================
  # Changeset
  # ==================================================

  def change_request(%Request{} = request, attrs \\ %{}) do
    Request.changeset(request, attrs)
  end

  def change_request(%User{} = user, %Category{} = category, attrs) do
    %Request{
      requestor: user,
      requestor_name: user.display_name,
      assignee_crew_id: category.assignee_crew_id,
      category: category,
      status: :validation
    }
    |> Request.changeset(attrs)
  end

  # ==================================================
  # CUD
  # ==================================================

  def create_request(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:requests)
    |> Request.changeset(attrs)
    |> Ecto.Changeset.put_change(:requestor_name, user.display_name)
    |> Repo.insert()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        Itsm.Utils.broadcasts(Request, {attrs["current_user"], :create_request, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def update_request(
        %User{id: user_id},
        %Request{requestor_id: user_id} = request,
        attrs
      ) do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        Itsm.Utils.broadcast(Request, {attrs["current_user"], :update_request, request})
        Itsm.Utils.broadcasts(Request, {attrs["current_user"], :update_request, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def delete_request(
        %User{id: user_id},
        %Request{requestor_id: user_id},
        %{"id" => id} = attrs
      ) do
    Repo.delete(get_request!(id))
    |> case do
      {:ok, request} ->
        Itsm.Utils.broadcast(Request, {attrs["current_user"], :delete_request, request})
        Itsm.Utils.broadcasts(Request, {attrs["current_user"], :delete_request, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end
end
