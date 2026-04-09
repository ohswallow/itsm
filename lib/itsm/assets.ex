defmodule Itsm.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Assets.Asset
  alias Itsm.Repo
  alias Itsm.OsInstances

  # 추후 db_instance, was_instance 등이 추가되면 이곳에 preload를 덧붙이면 됩니다.
  # @resource_preloads [:os_instance, :db_instances, :was_instances, :applications]
  @resource_preloads [:os_instance]

  # ==================================================
  # PubSub
  # ==================================================

  def subscribe_assets_list do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "assets_list")
  end

  def subscribe_asset(asset_id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "asset:#{asset_id}")
  end

  def broadcast_asset(asset, event_name) do
    # Index.ex의 handle_info와 포맷을 맞추기 위해 튜플로 묶습니다.
    # 예: {Itsm.Assets, [:asset, :created], %Asset{}}
    message = {__MODULE__, event_name, asset}
    Phoenix.PubSub.broadcast(Itsm.PubSub, "assets_list", message)
    Phoenix.PubSub.broadcast(Itsm.PubSub, "asset:#{asset.id}", message)

    # 함수 체이닝을 위해 결과를 반환해 줍니다.
    {:ok, asset}
  end

  @doc """
  Returns the list of assets.

  ## Examples

      iex> list_assets()
      [%Asset{}, ...]

  """
  def list_assets do
    Repo.all(Asset)
  end

  @doc """
  Gets a single asset.

  Raises `Ecto.NoResultsError` if the Asset does not exist.

  ## Examples

      iex> get_asset!(123)
      %Asset{}

      iex> get_asset!(456)
      ** (Ecto.NoResultsError)

  """
  def get_asset!(id), do: Repo.get!(Asset, id)

  @doc """
  Asset 단건 조회 시 연관된 Instance를 함께 가져옵니다.
  차후 db_instance, was_instance 등이 추가되면 이곳에 preload를 덧붙이면 됩니다.
  """
  def get_asset_with_relations!(id) do
    Asset
    |> Repo.get!(id)
    |> Repo.preload(
      @resource_preloads ++
        [
          service_crew: [:users],
          system_crew: [:users]
        ]
    )
  end

  @doc """
  Creates a asset.

  ## Examples

      iex> create_asset(%{field: value})
      {:ok, %Asset{}}

      iex> create_asset(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, asset} ->
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], :create_asset, asset})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :create_asset, asset})
        {:ok, asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a asset.

  ## Examples

      iex> update_asset(asset, %{field: new_value})
      {:ok, %Asset{}}

      iex> update_asset(asset, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, asset} ->
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], :update_asset, asset})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :update_asset, asset})
        {:ok, asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a asset.

  ## Examples

      iex> delete_asset(asset)
      {:ok, %Asset{}}

      iex> delete_asset(asset)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset(%{"id" => id} = attrs) do
    Repo.delete(get_asset!(id))
    |> case do
      {:ok, asset} ->
        Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], :delete_asset, asset})
        Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :delete_asset, asset})
        {:ok, asset}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.

  ## Examples

      iex> change_asset(asset)
      %Ecto.Changeset{data: %Asset{}}

  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  @doc """
  Asset과 OsInstance를 순차적으로 생성하되, 하나라도 실패하면 전체 롤백
  """
  def create_asset_with_os(request) do
    # embeds_many 리스트를 가져옵니다. (비어있을 경우를 대비해 빈 리스트 기본값)
    vm_list = request.common_k_create_vms || []

    # 트랜잭션 시작
    result =
      Repo.transaction(fn ->
        # VM 신청 대수만큼 반복(Loop)
        Enum.map(vm_list, fn vm_data ->
          # 1. Asset 속성 매핑 (vm_data에서 직접 추출)
          asset_attrs = %{
            name: vm_data.hostname,
            description: vm_data.service_name,
            category: request.category.category,
            infra_type: "private_cloud",
            env: request.env,
            region_type: request.category.group,
            affiliate: request.category.affiliate,
            location: vm_data.location,
            service_crew_id: request.requestor_crew_id,
            system_crew_id: request.assignee_crew_id,
            is_dmz_zone: vm_data.is_dmz_zone
          }

          with {:ok, asset} <- create_asset(asset_attrs),

               # 2. OS 속성 매핑 (위에서 생성된 asset.id를 FK로 삽입)
               os_attrs = %{
                 os_type: vm_data.os_image,
                 os_version: vm_data.os_version,
                 ip: vm_data.ip || "0.0.0.0",
                 cpu_core: vm_data.cpu,
                 memory_gb: vm_data.memory,
                 crew_id: request.assignee_crew_id,
                 # FK 삽입
                 asset_id: asset.id
               },
               {:ok, os_instance} <- OsInstances.create_os_instance(os_attrs) do
            # 둘 다 성공하면 결과 반환
            %{asset: asset, os_instance: os_instance}
          else
            # 실패 시 즉시 전체 트랜잭션 롤백

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end)
      end)

    case result do
      {:ok, created_items} ->
        # created_items는 [%{asset: asset1, ...}, %{asset: asset2, ...}] 형태의 리스트입니다.
        Enum.each(created_items, fn %{asset: asset} ->
          broadcast_asset(asset, [:asset, :created])
        end)

        {:ok, created_items}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def with_assoc(%Asset{} = asset, preloads) do
    Repo.preload(asset, preloads)
  end
end
