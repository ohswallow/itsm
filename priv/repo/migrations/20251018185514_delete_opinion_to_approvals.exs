defmodule Itsm.Repo.Migrations.DeleteOpinionToApprovals do
  use Ecto.Migration

  def change do
    alter table(:approvals) do
      remove :comment, :string
    end
  end
end
