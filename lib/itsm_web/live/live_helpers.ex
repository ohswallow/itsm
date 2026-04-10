defmodule ItsmWeb.LiveHelpers do
  defmacro __using__(opts) do
    only_common = Keyword.get(opts, :only_common, false)

    quote do
      def handle_event(event, params, socket)
          when event in ["save", "update", "delete"] and
                 is_map(params) and
                 not is_map_key(params, "use_help") do
        new_params =
          params
          |> inject_current_user(socket.assigns[:current_user])
          |> Map.put("use_help", true)

        handle_event(event, new_params, socket)
      end

      if !unquote(only_common) do
        on_mount {ItsmWeb.LiveHelpers, :default}

        def handle_info(
              %Phoenix.Socket.Broadcast{event: "all_codes_reload", payload: all_map},
              socket
            ) do
          {:noreply, push_event(socket, "common_code_all_reloaded", all_map)}
        end
      end

      defp inject_current_user(params, nil), do: params

      defp inject_current_user(params, user) do
        case Map.to_list(params) do
          [{key, value} | _] when is_map(value) ->
            Map.put(params, key, Map.put(value, "current_user", user))

          _ ->
            Map.put(params, "current_user", user)
        end
      end
    end
  end

  def on_mount(:default, _params, _session, socket) do
    if Phoenix.LiveView.connected?(socket) do
      ItsmWeb.Endpoint.subscribe("common_code:updates")
    end

    {:cont, socket}
  end
end
