defmodule Itsm.PubSub.Helper do
  import Phoenix.LiveView, only: [connected?: 1]

  def subscribe(socket_or_nil, domain, opts \\ [])

  def subscribe(%Phoenix.LiveView.Socket{} = socket, domain, opts) do
    if connected?(socket) do
      current_user = socket.assigns.current_user
      affiliate = Keyword.get(opts, :affiliate, find_affiliate(current_user))

      subscribe(nil, domain, Keyword.put(opts, :affiliate, affiliate))
    end

    socket
  end

  def subscribe(nil, domain, opts) do
    id = Keyword.get(opts, :id)
    only = Keyword.get(opts, :only, :all)
    affiliate = Keyword.get(opts, :affiliate)
    is_admin = Keyword.get(opts, :is_admin)

    if only in [:all, :list] do
      if is_admin do
        Phoenix.PubSub.subscribe(Itsm.PubSub, "admin:#{get_topic(domain)}")
      else
        if !is_nil(affiliate),
          do: Phoenix.PubSub.subscribe(Itsm.PubSub, "#{affiliate}:#{get_topic(domain)}")

        Phoenix.PubSub.subscribe(Itsm.PubSub, "common:#{get_topic(domain)}")
      end
    end

    if id && only in [:all, :detail] do
      if is_admin do
        Phoenix.PubSub.subscribe(Itsm.PubSub, "admin:#{get_topic(domain)}:#{id}")
      else
        if !is_nil(affiliate),
          do: Phoenix.PubSub.subscribe(Itsm.PubSub, "#{affiliate}:#{get_topic(domain)}:#{id}")

        Phoenix.PubSub.subscribe(Itsm.PubSub, "common:#{get_topic(domain)}:#{id}")
      end
    end
  end

  def broadcast(domain, message, opts \\ []) do
    id = Keyword.get(opts, :id)
    only = Keyword.get(opts, :only, :all)
    affiliate = Keyword.get(opts, :affiliate, extract_affiliate(message)) || "common"

    if only in [:all, :list] do
      topic = "#{get_topic(domain)}"

      Phoenix.PubSub.broadcast_from(
        Itsm.PubSub,
        self(),
        "#{affiliate}:#{topic}",
        {:pubsub, message}
      )

      Phoenix.PubSub.broadcast_from(Itsm.PubSub, self(), "admin:#{topic}", {:pubsub, message})
    end

    if id && only in [:all, :detail] do
      topic = "#{get_topic(domain)}:#{id}"

      Phoenix.PubSub.broadcast_from(
        Itsm.PubSub,
        self(),
        "#{affiliate}:#{topic}",
        {:pubsub, message}
      )

      Phoenix.PubSub.broadcast_from(Itsm.PubSub, self(), "admin:#{topic}", {:pubsub, message})
    end
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

  defp extract_affiliate({_user, _event, data}), do: find_affiliate(data)
  defp extract_affiliate({_event, data}), do: find_affiliate(data)
  defp extract_affiliate(data), do: find_affiliate(data)

  defp find_affiliate({data, _extra}) when is_map(data), do: find_affiliate(data)

  defp find_affiliate(%{affiliate: affiliate}), do: affiliate
  defp find_affiliate(%{organization_code: organization_code}), do: organization_code
  defp find_affiliate(%{organization: organization_code}), do: organization_code
  defp find_affiliate(%{category: %{affiliate: affiliate}}), do: affiliate

  defp find_affiliate(_), do: nil
end
