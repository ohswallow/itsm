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
        %User{} = user,
        %Category{} = category,
        crews,
        consumer_fn,
        attrs \\ %{}
      )
      when is_list(crews) and is_function(consumer_fn) do
    Multi.new()
    |> Multi.insert(:request, Requests.change_request(user, category, attrs))
    |> check_minimum_k_vms(attrs)
    |> Multi.run(:approval, fn repo, %{request: request} ->
      Approvals.create_approval(repo, request, user, attrs)
    end)
    |> Multi.run(:attachment, fn repo, %{request: request} ->
      Attachments.create_attachments(repo, request, consumer_fn, attrs)
    end)
    |> Multi.run(:crew_reference, fn repo, %{request: request} ->
      Crews.create_crew_references(repo, request, crews)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{request: request}} ->
        request = Repo.preload(request, [:category, :attachments])
        Approvals.broadcast_approvals_list({:request_created, request})
        Itsm.Utils.broadcasts(Requests, {user, :created_request, request})
        {:ok, request}

      error ->
        error
    end
  end

  def update_request(
        %Request{requestor_id: user_id} = request,
        consumer_fn,
        %{"current_user" => %{id: user_id}} = attrs
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:request, Request.changeset(request, attrs))
    |> Multi.run(:attachment, fn repo, %{request: request} ->
      Attachments.create_attachments(repo, request, consumer_fn, attrs)
    end)
    |> sync_crew_references(request, attrs["referenced_crews"])
    |> Repo.transact()
    |> case do
      {:ok, %{request: request}} ->
        request = Repo.preload(request, :category)
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], :update_request, request})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :update_request, request})
        {:ok, request}

      error ->
        error
    end
  end

  def create_comment(
        resource,
        %User{} = user,
        consumer_fn,
        attrs \\ %{}
      ) do
    Multi.new()
    |> Multi.insert(:comment, Comments.changeset_comment(resource, user, attrs))
    |> Multi.run(:attachments, fn repo, %{comment: comment} ->
      Attachments.create_attachments(repo, comment, consumer_fn, attrs)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{comment: comment, attachments: attachments}} ->
        Itsm.Utils.broadcasts(Comments, {user, :create_comment, comment})
        Itsm.Utils.broadcast(Requests, resource, {user, :create_comment, comment})
        Itsm.Utils.broadcasts(Attachments, {user, :create_attachments, attachments})
        {:ok, comment}

      {:error, _} = error ->
        error
    end
  end

  defp sync_crew_references(%Ecto.Multi{} = mult, %_{} = resource, crews_ids) do
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
      Crews.create_crew_references(repo, resource, Crews.get_crews(add_id_list))
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
end
