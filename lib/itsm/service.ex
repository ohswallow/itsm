defmodule Itsm.Service do
  @moduledoc """
  The Service context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Itsm.Repo
  alias Itsm.Service.Category
  alias Itsm.Accounts.User
  alias Itsm.Attachments
  alias Itsm.Requests
  alias Itsm.Service.Request
  alias Itsm.Approvals
  alias Itsm.Comments
  alias Itsm.Crews

  def create_request(
        %User{} = user,
        %Category{} = category,
        crews,
        handle_attachments,
        attrs \\ %{}
      )
      when is_list(crews) and is_function(handle_attachments) do
    Multi.new()
    |> Multi.insert(:request, Requests.change_request(user, category, attrs))
    |> Multi.run(:approval, fn repo, %{request: request} ->
      Approvals.create_approval(repo, request, user, attrs)
    end)
    |> Multi.run(:attachment, fn repo, %{request: request} ->
      Attachments.create_attachments(repo, request, handle_attachments, attrs)
    end)
    |> Multi.run(:crew_reference, fn repo, %{request: request} ->
      Crews.create_crew_references(repo, request, crews)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{request: request}} ->
        request = Repo.preload(request, [:category, :attachments])
        Approvals.broadcast_approvals_list({:request_created, request})
        Itsm.Utils.broadcasts(Request, {user, :created_request, request})
        {:ok, request}

      error ->
        error
    end
  end

  def create_comment(resource, %User{} = user, handle_attachments, attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:comment, Comments.changeset_comment(resource, user, attrs))
    |> Multi.run(:attachments, fn repo, %{comment: comment} ->
      Attachments.create_attachments(repo, comment, handle_attachments, attrs)
    end)
    |> Repo.transaction()
    |> Comments.broadcast_result(attrs["current_user"], resource)
  end
end
