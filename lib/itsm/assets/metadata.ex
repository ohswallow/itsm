defmodule Itsm.Assets.Metadata do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    embeds_one :server, Itsm.Assets.Metadata.Server, on_replace: :update
    embeds_one :network, Itsm.Assets.Metadata.Network, on_replace: :update
    embeds_one :storage, Itsm.Assets.Metadata.Storage, on_replace: :update
  end

  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [])
    |> cast_embed(:server)
    |> cast_embed(:network)
    |> cast_embed(:storage)
    |> remove_nil_embeds()
  end

  defp remove_nil_embeds(changeset) do
    keys_to_drop = [:server, :network, :storage]

    Enum.reduce(keys_to_drop, changeset, fn key, acc ->
      if get_field(acc, key) == nil do
        delete_change(acc, key)
      else
        acc
      end
    end)
  end
end
