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

  def broadcast(domain, {_event, item} = message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "#{domain}:#{item.id}", {:pubsub, message})
  end

  def broadcasts(domain, message) do
    Phoenix.PubSub.broadcast(Itsm.PubSub, "#{domain}", {:pubsub, message})
  end

  def subscribe(domain, id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "#{domain}:#{id}")
  end

  def subscribes(domain) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "#{domain}")
  end
end
