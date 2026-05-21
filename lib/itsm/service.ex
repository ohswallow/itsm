defmodule Itsm.Service do
  @moduledoc """
  The Service context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Itsm.Repo
  alias Itsm.Service.Category
  alias Itsm.Accounts.User
  alias Itsm.Service.Request
  alias Itsm.Attachments
  alias Itsm.Requests
  alias Itsm.Approvals
  alias Itsm.Comments
  alias Itsm.Crews

  def create_request(
        %User{} = action_user,
        %Category{} = category,
        crews,
        consumer_fn,
        attrs \\ %{}
      )
      when is_list(crews) and is_function(consumer_fn) do
    Multi.new()
    |> Multi.insert(:request, Requests.change_request(action_user, category, attrs))
    |> check_minimum_k_vms(attrs)
    |> Multi.run(:approval, fn repo, %{request: request} ->
      Approvals.create_approval(action_user, repo, request)
    end)
    |> Multi.run(:attachment, fn repo, %{request: request} ->
      Attachments.create_attachments(action_user, repo, request, consumer_fn)
    end)
    |> Multi.run(:crew_reference, fn repo, %{request: request} ->
      Crews.create_crew_references(action_user, repo, request, crews)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{request: request}} ->
        request = Repo.preload(request, [:category, :attachments])
        Itsm.PubSub.Helper.broadcast(Requests, {action_user, :create_request, request})
        {:ok, request}

      error ->
        error
    end
  end

  def update_request(
        %User{id: user_id} = action_user,
        %Request{requestor_id: user_id} = request,
        consumer_fn,
        attrs
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:request, Request.changeset(request, attrs))
    |> Multi.run(:attachment, fn repo, %{request: request} ->
      Attachments.create_attachments(action_user, repo, request, consumer_fn)
    end)
    |> sync_crew_references(action_user, request, attrs["referenced_crews"])
    |> Repo.transact()
    |> case do
      {:ok, %{request: request}} ->
        request = Repo.preload(request, :category)

        Itsm.PubSub.Helper.broadcast(Requests, {action_user, :update_request, request},
          id: request.id
        )

        {:ok, request}

      error ->
        error
    end
  end

  def delete_request(%User{} = action_user, request_id) do
    request = Requests.get_request!(request_id)

    with :ok <- ensure_requestor(action_user, request),
         {:ok, %{delete_request: deleted_request, delete_approval: deleted_approve}} <-
           delete_request_mult(request) do
      Itsm.PubSub.Helper.broadcast(Requests, {action_user, :delete_request, deleted_request},
        id: deleted_request.id
      )

      Itsm.PubSub.Helper.broadcast(Approvals, {action_user, :delete_approval, deleted_approve},
        id: deleted_approve.id
      )

      {:ok, request}
    else
      error ->
        error
    end
  end

  def create_comment(
        %User{} = action_user,
        resource,
        consumer_fn,
        attrs \\ %{}
      ) do
    Multi.new()
    |> Multi.insert(:comment, Comments.changeset_comment(action_user, resource, attrs))
    |> Multi.run(:attachments, fn repo, %{comment: comment} ->
      Attachments.create_attachments(action_user, repo, comment, consumer_fn)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{comment: comment, attachments: attachments}} ->
        Itsm.PubSub.Helper.broadcast(Requests, {action_user, :create_comment, comment},
          id: resource.id,
          only: :detail
        )

        Itsm.PubSub.Helper.broadcast(Comments, {action_user, :create_comment, comment})
        Itsm.PubSub.Helper.broadcast(Attachments, {action_user, :create_attachments, attachments})
        {:ok, comment}

      {:error, _} = error ->
        error
    end
  end

  defp sync_crew_references(
         %Ecto.Multi{} = mult,
         %User{} = action_user,
         %_{} = resource,
         crews_ids
       ) do
    mult
    |> Ecto.Multi.run(:diff, fn repo, _ ->
      db_crew_references = Crews.list_crew_reference(repo, resource)
      db_crew_ids = Enum.map(db_crew_references, & &1.crew_id)

      crews_set = MapSet.new(crews_ids)
      db_crews_set = MapSet.new(db_crew_ids)

      add_id_list = MapSet.difference(crews_set, db_crews_set) |> MapSet.to_list()
      ids_to_delete = MapSet.difference(db_crews_set, crews_set) |> MapSet.to_list()

      delete_list = Enum.filter(db_crew_references, &(&1.crew_id in ids_to_delete))
      {:ok, %{add_id_list: add_id_list, delete_list: delete_list}}
    end)
    |> Ecto.Multi.run(:delete, fn repo, %{diff: %{delete_list: delete_list}} ->
      Enum.reduce_while(delete_list, {:ok, []}, fn crew_reference, {:ok, acc} ->
        case repo.delete(crew_reference) do
          {:ok, _} ->
            {:cont, {:ok, [crew_reference | acc]}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)
    end)
    |> Ecto.Multi.run(:create, fn repo, %{diff: %{add_id_list: add_id_list}} ->
      Crews.create_crew_references(action_user, repo, resource, Crews.get_crews(add_id_list))
    end)
  end

  defp check_minimum_k_vms(%Ecto.Multi{} = multi, params) do
    vms = params["common_k_create_vms"] || []

    if Enum.empty?(vms) do
      Ecto.Multi.error(multi, :k_vms_required, "minimum 1 VM must be inputed")
    else
      multi
    end
  end

  def delete_request_mult(%Request{} = request) do
    Multi.new()
    |> Multi.delete(:delete_approval, Approvals.get_approval_by_request(request))
    |> Multi.delete(:delete_request, request)
    |> Repo.transact()
  end

  defp ensure_requestor(%User{id: id}, %Request{requestor_id: id}), do: :ok
  defp ensure_requestor(_action_user, _request), do: {:error, :not_requestor}
end
