defmodule ItsmWeb.LiveHelpers do
  defmacro __using__(_opts) do
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
end
