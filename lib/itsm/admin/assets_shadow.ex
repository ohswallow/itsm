defmodule Itsm.Admin.AssetsShadow do
  import Ecto.Query, warn: false

  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Assets.{AssetShadow, Asset}

  def list_assets_shadow_with_crew do
    AssetShadow
    |> preload([:service_crew, :system_crew])
    |> Repo.all()
  end

  def get_asset_shadow!(id), do: Repo.get!(AssetShadow, id) |> Repo.preload([:asset])

  def change_asset_shadow(%AssetShadow{} = asset_shadow, attrs \\ %{}) do
    category = attrs["category"] || attrs[:category] || asset_shadow.category

    default_metadata =
      case Asset.get_metadata_registry() |> Map.get(category) do
        nil ->
          nil

        module ->
          struct(module)
      end

    asset_shadow_with_default =
      if default_metadata && is_nil(asset_shadow.metadata) do
        %{asset_shadow | metadata: default_metadata}
      else
        asset_shadow
      end

    AssetShadow.changeset(asset_shadow_with_default, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def create_asset_shadow(%User{} = action_user, attrs) do
    %AssetShadow{}
    |> AssetShadow.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, asset_shadow} ->
        Itsm.PubSub.Helper.broadcast(
          __MODULE__,
          {action_user, :create_asset_shadow, asset_shadow}
        )

        {:ok, asset_shadow}

      error ->
        error
    end
  end

  def update_asset_shadow(%User{} = action_user, %AssetShadow{} = asset_shadow, attrs) do
    asset_shadow
    |> AssetShadow.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, asset_shadow} ->
        Itsm.PubSub.Helper.broadcast(
          __MODULE__,
          {action_user, :update_asset_shadow, asset_shadow},
          id: asset_shadow.id
        )

        {:ok, asset_shadow}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_asset_shadow(%User{} = action_user, %{"id" => id}) do
    get_asset_shadow!(id)
    |> Repo.delete()
    |> case do
      {:ok, asset_shadow} ->
        Itsm.PubSub.Helper.broadcast(
          __MODULE__,
          {action_user, :delete_asset_shadow, asset_shadow},
          id: asset_shadow.id
        )

        {:ok, asset_shadow}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def with_assoc(%AssetShadow{} = asset_shadow, preloads),
    do: Repo.preload(asset_shadow, preloads)

  def metadata_fields_for_category(nil), do: %{}

  def metadata_fields_for_category(category) do
    Asset.metadata_fields_for_category(category)
  end
end
