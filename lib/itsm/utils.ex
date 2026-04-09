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

  def broadcast(domain, %{id: id}, message) do
    topic = "#{get_topic(domain)}:#{id}"
    Phoenix.PubSub.broadcast_from(Itsm.PubSub, self(), topic, {:pubsub, message})
  end

  def broadcast(domain, message) do
    topic = "#{get_topic(domain)}:#{extract_id(message)}"
    Phoenix.PubSub.broadcast_from(Itsm.PubSub, self(), topic, {:pubsub, message})
  end

  def broadcasts(domain, message) do
    Phoenix.PubSub.broadcast_from(Itsm.PubSub, self(), "#{get_topic(domain)}", {:pubsub, message})
  end

  def subscribe(domain, id) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "#{get_topic(domain)}:#{id}")
  end

  def subscribes(domain) do
    Phoenix.PubSub.subscribe(Itsm.PubSub, "#{get_topic(domain)}")
  end

  defp get_topic(%{__struct__: module}), do: extract_domain(module)

  defp get_topic(module) when is_atom(module) do
    if module |> to_string() |> String.starts_with?("Elixir."),
      do: extract_domain(module),
      else: module
  end

  defp get_topic(anything_else), do: anything_else

  defp extract_domain(input) do
    input
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp extract_id({_user, _event, data}), do: find_id(data)
  defp extract_id({_event, data}), do: find_id(data)

  defp find_id(%{id: id}), do: id
  defp find_id({%{id: id}, _extra}), do: id
  defp find_id(_), do: nil
end
