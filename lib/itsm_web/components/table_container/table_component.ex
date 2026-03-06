defmodule ItsmWeb.TableContainerComponent do
  use ItsmWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns)}
  end

  @impl true
  def handle_event("update-filters", params, socket) do
    query_params = %{
      "search" => params["search"] || "",
      "page" => 1,
      "page_size" => params["page_size"] || 10,
      "search_columns" => params["search_columns"]
    }

    {:noreply,
     push_patch(socket,
       to: "#{socket.assigns.results.current_path}?#{Plug.Conn.Query.encode(query_params)}"
     )}
  end
end
