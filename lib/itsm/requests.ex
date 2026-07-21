defmodule Itsm.Requests do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Service.Request
  alias Itsm.Service.Category
  alias Itsm.Accounts.User

  def get_request!(id) do
    Request
    |> Repo.get!(id)
  end

  def with_assoc(%Request{} = request, preloads) do
    Repo.preload(request, preloads)
  end

  def assign_referenced_crews(%Request{crew_references: crew_refs} = request) do
    %{request | referenced_crews: Enum.map(crew_refs, & &1.crew_id)}
  end

  def change_request(%Request{} = request, attrs \\ %{}) do
    Request.changeset(ensure_has_vm(request), attrs)
  end

  defp ensure_has_vm(%Request{common_k_create_vms: vms} = request) when vms in [nil, []] do
    %{request | common_k_create_vms: [%Itsm.Service.CommonKCreateVm{}]}
  end

  defp ensure_has_vm(%Request{} = request), do: request

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

  def create_request(%User{} = action_user, attrs) do
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

  def create_request(
        %User{} = action_user,
        %Category{} = catrgory,
        attrs,
        repo \\ Repo,
        opts \\ []
      ) do
    action_user
    |> change_request(catrgory, attrs)
    |> repo.insert()
    |> case do
      {:ok, request} ->
        request = repo.preload(request, :category)

        if Keyword.get(opts, :broadcast, true) do
          Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_request, request})
        end

        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def update_request(repo, %Request{} = request, attrs) do
    request
    |> Request.changeset(attrs)
    |> repo.update()
    |> case do
      {:ok, request} -> {:ok, request}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete_request(%User{id: user_id} = action_user, %Request{requestor_id: user_id}, %{
        "id" => id
      }) do
    get_request!(id)
    |> Repo.delete()
    |> case do
      {:ok, request} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_request, request},
          id: request.id
        )

        {:ok, request}

      {:error, _} = error ->
        error
    end
  end
end
