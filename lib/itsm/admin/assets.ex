defmodule Itsm.Admin.Assets do
  import Ecto.Query, warn: false

  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Assets.Asset

  def get_asset!(id), do: Repo.get!(Asset, id)

  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def create_asset(%User{} = action_user, attrs) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, asset} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_asset, asset})

        {:ok, asset}

      error ->
        error
    end
  end

  def update_asset(%User{} = action_user, %Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, asset} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_asset, asset},
          id: asset.id
        )

        {:ok, asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_asset(%User{} = action_user, %{"id" => id}) do
    get_asset!(id)
    |> Repo.delete()
    |> case do
      {:ok, asset} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_asset, asset},
          id: asset.id
        )

        {:ok, asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def with_assoc(%Asset{} = asset, preloads), do: Repo.preload(asset, preloads)
end
