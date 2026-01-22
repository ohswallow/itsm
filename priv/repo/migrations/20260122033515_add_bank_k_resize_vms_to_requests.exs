defmodule Itsm.Repo.Migrations.AddBankKResizeVmsToRequests do
  use Ecto.Migration

  def change do
    alter table(:requests) do
      add :bank_k_resize_vms, :map
    end
  end
end
