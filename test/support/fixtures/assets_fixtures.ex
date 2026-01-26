defmodule Itsm.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Assets` context.
  """

  @doc """
  Generate a unique asset name.
  """
  def unique_asset_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a asset.
  """
  def asset_fixture(attrs \\ %{}) do
    {:ok, asset} =
      attrs
      |> Enum.into(%{
        affiliate: :A0,
        category: :server,
        description: "some description",
        env: :prod,
        infra_type: :on_premise,
        is_dmz_zone: true,
        location: :yeouido_it,
        name: unique_asset_name(),
        region_type: :P_region
      })
      |> Itsm.Assets.create_asset()

    asset
  end
end
