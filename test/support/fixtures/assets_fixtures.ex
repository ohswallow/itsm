defmodule Itsm.AssetsFixtures do
  alias Itsm.Accounts.User

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
    attrs =
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

    {:ok, asset} = Itsm.Assets.create_asset(%User{}, attrs)

    asset
  end
end
