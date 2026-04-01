defmodule Itsm.Admin.Assets do
  import Ecto.Query, warn: false

  alias Itsm.Repo
  alias Itsm.Assets.Asset

  def get_asset!(id), do: Repo.get!(Asset, id)

  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  defdelegate create_asset(attrs \\ %{}), to: Itsm.Assets

  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, asset} ->
        event = :update_asset
        Itsm.Utils.broadcast(Asset, {attrs["current_user"], event, asset})
        Itsm.Utils.broadcasts(Asset, {attrs["current_user"], event, asset})
        {:ok, asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_asset(%{"id" => id} = attrs) do
    Repo.delete(get_asset!(id))
    |> case do
      {:ok, asset} ->
        event = :delete_asset
        Itsm.Utils.broadcast(Asset, {attrs["current_user"], event, asset})
        Itsm.Utils.broadcasts(Asset, {attrs["current_user"], event, asset})
        {:ok, asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
