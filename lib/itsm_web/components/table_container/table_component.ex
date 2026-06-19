defmodule ItsmWeb.TableContainerComponent do
  use ItsmWeb, :live_component

  @default_page 1
  @default_page_size 10
  @date_range_days 30

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> init_default_value()}
  end

  def handle_event("update-filters", params, socket) do
    %{current_path: current_path, params: current_params} = socket.assigns.results
    merge_params = Map.merge(current_params, Itsm.Paging.converter_params(params))

    {:noreply, push_patch(socket, to: "#{current_path}?#{Plug.Conn.Query.encode(merge_params)}")}
  end

  defp init_default_value(socket) do
    current_results = socket.assigns[:results] || %{}

    socket
    |> assign(:results, build_results(current_results))
  end

  defp build_results(current_results) do
    Map.merge(current_results, %{
      params: Map.merge(default_params(), Itsm.Paging.converter_params(current_results[:params])),
      columns_options: current_results[:columns_options] || [],
      current_path: current_results[:current_path] || "",
      total_count: current_results[:total_count] || 0,
      total_pages: current_results[:total_pages] || 0,
      range_column_options: current_results[:range_column_options] || []
    })
  end

  defp default_params do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %{
      search: "",
      page: @default_page,
      page_size: @default_page_size,
      search_columns: [],
      start_date: now |> DateTime.add(-@date_range_days, :day) |> DateTime.to_string(),
      end_date: now |> DateTime.add(@date_range_days, :day) |> DateTime.to_string(),
      range_column: nil
    }
  end
end
