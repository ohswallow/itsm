defmodule ItsmWeb.TableContainerComponent do
  use ItsmWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> init_default_value()}
  end

  @impl true
  def handle_event("update-filters", params, socket) do
    query_params = %{
      "search" => params["search"],
      "page" => 1,
      "page_size" => params["page_size"],
      "search_columns" => params["search_columns"]
    }

    {:noreply,
     push_patch(socket,
       to: "#{socket.assigns.results.current_path}?#{Plug.Conn.Query.encode(query_params)}"
     )}
  end

  defp init_default_value(socket) do
    current_results = get_in(socket.assigns, [:results]) || %{}

    default_params = %{search: "", page: 1, page_size: 10, search_columns: [""]}
    safe_params = Map.merge(default_params, current_results[:params] || %{})

    updated_results =
      Map.merge(current_results, %{
        params: safe_params,
        columns_options: current_results[:columns_options] || [""],
        current_path: current_results[:current_path] || "",
        total_count: current_results[:total_count] || 0,
        total_pages: current_results[:total_pages] || 0
      })

    socket
    |> assign(:results, updated_results)
  end
end
