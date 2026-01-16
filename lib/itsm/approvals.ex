defmodule Itsm.Approvals do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Accounts.User
  alias Itsm.Service.Approval
  alias Itsm.Service.Request

  def subscribe_approvals_list do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "approvals_list")
  end

  def broadcast_approvals_list(message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "approvals_list", message)
  end

  def list_approvals do
    Repo.all(Approval)
  end

  def get_approval!(id), do: Repo.get!(Approval, id)

  def change_approval(%Approval{} = approval, attrs \\ %{}) do
    Approval.changeset(approval, attrs)
  end

  def create_approval(attrs \\ %{}) do
    %Approval{}
    |> Approval.changeset(attrs)
    |> Repo.insert()
  end

  def create_approval(repo, %Request{} = request, %User{} = user) do
    %Approval{
      approver: user,
      approver_name: user.display_name,
      request: request
    }
    |> Approval.changeset(%{})
    |> repo.insert()
  end

  def update_approval(%Approval{} = approval, attrs) do
    approval
    |> Approval.changeset(attrs)
    |> Repo.update()
  end

  def delete_approval(%Approval{} = approval) do
    Repo.delete(approval)
  end
end
