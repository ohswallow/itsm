defmodule Itsm.AssetsTest do
  use Itsm.DataCase

  alias Itsm.Assets

  describe "assets" do
    alias Itsm.Assets.Asset

    import Itsm.AssetsFixtures

    @invalid_attrs %{env: nil, name: nil, description: nil, location: nil, category: nil, affiliate: nil, region_type: nil, infra_type: nil, is_dmz_zone: nil}

    test "list_assets/0 returns all assets" do
      asset = asset_fixture()
      assert Assets.list_assets() == [asset]
    end

    test "get_asset!/1 returns the asset with given id" do
      asset = asset_fixture()
      assert Assets.get_asset!(asset.id) == asset
    end

    test "create_asset/1 with valid data creates a asset" do
      valid_attrs = %{env: :prod, name: "some name", description: "some description", location: :yeouido_it, category: :server, affiliate: :A0, region_type: :P_region, infra_type: :on_premise, is_dmz_zone: true}

      assert {:ok, %Asset{} = asset} = Assets.create_asset(valid_attrs)
      assert asset.env == :prod
      assert asset.name == "some name"
      assert asset.description == "some description"
      assert asset.location == :yeouido_it
      assert asset.category == :server
      assert asset.affiliate == :A0
      assert asset.region_type == :P_region
      assert asset.infra_type == :on_premise
      assert asset.is_dmz_zone == true
    end

    test "create_asset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_asset(@invalid_attrs)
    end

    test "update_asset/2 with valid data updates the asset" do
      asset = asset_fixture()
      update_attrs = %{env: :stg, name: "some updated name", description: "some updated description", location: :gimpo_it, category: :network, affiliate: :B0, region_type: :K_region_common, infra_type: :aws, is_dmz_zone: false}

      assert {:ok, %Asset{} = asset} = Assets.update_asset(asset, update_attrs)
      assert asset.env == :stg
      assert asset.name == "some updated name"
      assert asset.description == "some updated description"
      assert asset.location == :gimpo_it
      assert asset.category == :network
      assert asset.affiliate == :B0
      assert asset.region_type == :K_region_common
      assert asset.infra_type == :aws
      assert asset.is_dmz_zone == false
    end

    test "update_asset/2 with invalid data returns error changeset" do
      asset = asset_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_asset(asset, @invalid_attrs)
      assert asset == Assets.get_asset!(asset.id)
    end

    test "delete_asset/1 deletes the asset" do
      asset = asset_fixture()
      assert {:ok, %Asset{}} = Assets.delete_asset(asset)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_asset!(asset.id) end
    end

    test "change_asset/1 returns a asset changeset" do
      asset = asset_fixture()
      assert %Ecto.Changeset{} = Assets.change_asset(asset)
    end
  end
end
