defmodule Itsm.Admin.Assets do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Assets.Asset

  def get_asset!(id), do: Repo.get!(Asset, id)

  def list_assets do
    Repo.all(Asset)
  end

  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs[:inserted_at])
  end

  defdelegate create_asset(attrs \\ %{}), to: Itsm.Assets

  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs[:inserted_at])
    |> Repo.update()
  end

  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end
end
