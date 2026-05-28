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
        attrs
      )
      when is_list(crews) and is_function(consumer_fn) do
    Multi.new()
    |> Multi.run(:create_request, fn repo, _ ->
      Requests.create_request(action_user, category, attrs, repo, broadcast: false)
    end)
    |> check_minimum_k_vms(attrs)
    |> Multi.run(:create_approval, fn repo, %{create_request: request} ->
      Approvals.create_approval(action_user, repo, request, broadcast: false)
    end)
    |> Multi.run(:create_attachments, fn repo, %{create_request: request} ->
      Attachments.create_attachments(action_user, request, consumer_fn, repo, broadcast: false)
    end)
    |> Multi.run(:create_crew_references, fn repo, %{create_request: request} ->
      Crews.create_crew_references(action_user, request, crews, repo, broadcast: false)
    end)
    |> Repo.transact()
    |> case do
      {:ok,
       %{
         create_request: request,
         create_approval: approval,
         create_attachments: attachments
       }} ->
        request = Repo.preload(request, [:category])

        Itsm.PubSub.Helper.broadcast(Requests, {action_user, :create_request, request})
        Itsm.PubSub.Helper.broadcast(Approvals, {action_user, :create_approval, approval})
        Itsm.PubSub.Helper.broadcast(Attachments, {action_user, :create_attachments, attachments})

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
    |> Multi.run(:update_request, fn repo, _ ->
      Requests.update_request(action_user, request, attrs, repo, broadcast: false)
    end)
    |> Multi.run(:create_attachments, fn repo, %{update_request: request} ->
      Attachments.create_attachments(action_user, request, consumer_fn, repo, broadcast: false)
    end)
    |> sync_crew_references(action_user, request, attrs["referenced_crews"])
    |> Repo.transact()
    |> case do
      {:ok, %{update_request: request, create_attachments: attachment}} ->
        request = Repo.preload(request, :category)

        Itsm.PubSub.Helper.broadcast(Requests, {action_user, :update_request, request},
          id: request.id
        )

        Itsm.PubSub.Helper.broadcast(Attachments, {action_user, :create_attachments, attachment})

        {:ok, request}

      error ->
        error
    end
  end

  def delete_request(%User{} = action_user, request_id) do
    request = Requests.get_request!(request_id)

    with :ok <- ensure_requestor(action_user, request),
         {:ok, %{delete_request: request, delete_approval: approve}} <-
           delete_request_mult(action_user, request, broadcast: false) do
      Itsm.PubSub.Helper.broadcast(Requests, {action_user, :delete_request, request},
        id: request.id
      )

      Itsm.PubSub.Helper.broadcast(Approvals, {action_user, :delete_approval, approve},
        id: approve.id
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
        attrs
      ) do
    Multi.new()
    |> Multi.run(:create_comment, fn repo, _ ->
      Comments.create_comment(action_user, resource, attrs, repo, broadcast: false)
    end)
    |> Multi.run(:create_attachments, fn repo, %{create_comment: comment} ->
      Attachments.create_attachments(action_user, comment, consumer_fn, repo, broadcast: false)
    end)
    |> Repo.transact()
    |> case do
      {:ok, %{create_comment: comment, create_attachments: attachment}} ->
        Itsm.PubSub.Helper.broadcast(Requests, {action_user, :create_comment, comment},
          id: resource.id,
          only: :detail
        )

        Itsm.PubSub.Helper.broadcast(Comments, {action_user, :create_comment, comment})
        Itsm.PubSub.Helper.broadcast(Attachments, {action_user, :create_attachments, attachment})

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
      Crews.create_crew_references(action_user, resource, Crews.get_crews(add_id_list), repo,
        broadcast: false
      )
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

  def delete_request_mult(%User{} = action_user, %Request{} = request, opts \\ []) do
    Multi.new()
    |> Multi.delete(:delete_approval, Approvals.get_approval_by_request(request))
    |> Multi.delete(:delete_request, request)
    |> Repo.transact()
    |> case do
      {:ok, %{delete_approval: approval, delete_request: request}} ->
        if Keyword.get(opts, :broadcast, true) do
          Itsm.PubSub.Helper.broadcast(Requests, {action_user, :delete_request, request},
            id: request.id
          )

          Itsm.PubSub.Helper.broadcast(Approvals, {action_user, :delete_approval, approval},
            id: request.id
          )
        end

        {:ok, request}

      error ->
        error
    end
  end

  defp ensure_requestor(%User{id: id}, %Request{requestor_id: id}), do: :ok
  defp ensure_requestor(_action_user, _request), do: {:error, :not_requestor}
end
