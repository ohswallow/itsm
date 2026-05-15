defmodule Itsm.Utils do
  @moduledoc """
  ITSM 개발에 필요한 BIZ모듈에서 사용할 Util메소드 정의 합니다.
  """
  def resource_name(%module{}) do
    module
    |> Module.split()
    |> List.last()
  end

  def maybe_put_change(changeset, _field, nil), do: changeset

  def maybe_put_change(changeset, field, value) when is_binary(value) do
    parse_and_put(changeset, field, value, DateTime.from_iso8601(value))
  end

  def maybe_put_change(changeset, field, value) do
    Ecto.Changeset.put_change(changeset, field, value)
  end

  defp parse_and_put(changeset, field, _value, {:ok, dt, _offset}) do
    Ecto.Changeset.put_change(changeset, field, DateTime.truncate(dt, :second))
  end

  defp parse_and_put(changeset, field, value, {:error, _reason}) do
    Ecto.Changeset.put_change(changeset, field, value)
  end

  def maybe_parse_json(attrs, key) do
    metadata = attrs[Atom.to_string(key)] || attrs[key]

    if is_binary(metadata) && metadata != "" do
      case Jason.decode(metadata) do
        {:ok, decoded} ->
          Map.put(attrs, "metadata", decoded)

        {:error, _} ->
          attrs
      end
    else
      attrs
    end
  end

  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(_), do: false
end
