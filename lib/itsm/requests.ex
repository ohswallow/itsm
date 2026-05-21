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
end
