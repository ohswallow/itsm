defmodule Itsm.Admin.Assets do
  import Ecto.Query, warn: false

  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Assets.{Asset, AssetRelation}

  def list_assets_with_crew do
    Asset
    |> preload([:service_crew, :system_crew])
    |> Repo.all()
  end

  def get_asset!(id), do: Repo.get!(Asset, id) |> Repo.preload([:relation_assets])

  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    category = attrs["category"] || attrs[:category] || asset.category

    default_metadata =
      case category do
        "서버" -> %Itsm.Assets.Metadata.Server{}
        "네트워크" -> %Itsm.Assets.Metadata.Network{}
        "스토리지" -> %Itsm.Assets.Metadata.Storage{}
        _ -> nil
      end

    asset_with_default =
      if default_metadata && is_nil(asset.metadata) do
        %{asset | metadata: default_metadata}
      else
        asset
      end

    Asset.changeset(asset_with_default, attrs)
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

  def connect_assets(asset, target_ids) do
    Enum.reduce(target_ids, Ecto.Multi.new(), fn id, acc ->
      Ecto.Multi.run(acc, {:connect, id}, __MODULE__, :connect_assets_with_repo, [asset.id, id])
    end)
    |> Repo.transaction()
  end

  def connect_assets_with_repo(_repo, _changes, id_1, id_2) when id_1 == id_2,
    do: {:error, "자기 자신과 연결할 수 없습니다."}

  def connect_assets_with_repo(repo, _changes, id_1, id_2) do
    str_id_1 = Ecto.UUID.cast!(id_1)
    str_id_2 = Ecto.UUID.cast!(id_2)

    [asset_a_id, asset_b_id] = Enum.sort([str_id_1, str_id_2])

    %AssetRelation{}
    |> AssetRelation.changeset(%{asset_a_id: asset_a_id, asset_b_id: asset_b_id})
    |> repo.insert()
  end

  def disconnect_assets(id_1, id_2) do
    str_id_1 = Ecto.UUID.cast!(id_1)
    str_id_2 = Ecto.UUID.cast!(id_2)

    [asset_a_id, asset_b_id] = Enum.sort([str_id_1, str_id_2])

    query =
      from(r in AssetRelation,
        where: r.asset_a_id == ^asset_a_id and r.asset_b_id == ^asset_b_id
      )

    Repo.delete_all(query)
  end

  def metadata_fields_for_category(category) do
    Asset.metadata_fields_for_category(category)
  end
end
