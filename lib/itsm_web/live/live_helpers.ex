defmodule ItsmWeb.LiveHelpers do
  defmacro __using__(opts) do
    only_common = Keyword.get(opts, :only_common, false)

    quote do
      if !unquote(only_common) do
        on_mount {ItsmWeb.LiveHelpers, :default}

        def handle_info(
              %Phoenix.Socket.Broadcast{event: "all_codes_reload", payload: all_map},
              socket
            ) do
          {:noreply, push_event(socket, "common_code_all_reloaded", all_map)}
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
