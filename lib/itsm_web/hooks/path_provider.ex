defmodule ItsmWeb.PathProvider do
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:set_current_path_on_assigns, _params, _session, socket) do
    {:cont,
     attach_hook(socket, :set_current_path_on_assigns, :handle_params, fn _params, uri, socket ->
       {:cont, assign(socket, :current_path, URI.parse(uri).path)}
     end)}
  end
end
