defmodule ItsmWeb.CalendarComponent do
  use ItsmWeb, :live_component

  @col_classes %{
    1 => "col-start-1",
    2 => "col-start-2",
    3 => "col-start-3",
    4 => "col-start-4",
    5 => "col-start-5",
    6 => "col-start-6",
    7 => "col-start-7"
  }

  def update(assigns, socket) do
    errors =
      if Phoenix.Component.used_input?(assigns[:field]), do: assigns[:field].errors, else: []

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:errors, Enum.map(errors, &translate_error(&1)))
     |> assign_initial_values()
     |> update_calendar_grid()}
  end

  def handle_event("shift", %{"unit" => unit, "amount" => amount}, socket) do
    new_date =
      socket.assigns.view_date
      |> Date.beginning_of_month()
      |> Date.shift([{String.to_existing_atom(unit), String.to_integer(amount)}])
      |> Date.beginning_of_month()

    {:noreply, socket |> assign(view_date: new_date) |> update_calendar_grid()}
  end

  def handle_event("selected_date_time", %{"datetime" => datetime}, socket) do
    {:noreply,
     socket
     |> assign(selected_date_time: datetime |> DateTime.from_iso8601() |> elem(1))}
  end

  defp assign_initial_values(socket) do
    defaults = %{
      label: %{},
      container: %{},
      selected_date_time: %{},
      popup: %{},
      grid: %{},
      date: %{},
      hour: %{},
      minute: %{}
    }

    socket
    |> assign_new(:id, fn -> socket.assigns[:field] && socket.assigns[:field].id end)
    |> assign_new(:view_date, fn ->
      socket.assigns[:default_view_date] || Date.utc_today()
    end)
    |> assign_new(:selected_date_time, fn ->
      socket.assigns[:default_selected_date_time]
    end)
    |> assign_new(:show_time, fn -> false end)
    |> assign(:rests, Map.merge(defaults, socket.assigns[:rests]))
  end

  defp update_calendar_grid(%{assigns: assigns} = socket) do
    socket
    |> assign(
      :days,
      Date.range(Date.beginning_of_month(assigns.view_date), Date.end_of_month(assigns.view_date))
      |> Enum.map(&build_day_map(&1, assigns[:min], assigns[:max], assigns[:disabled_dates]))
    )
    |> assign(
      :start_col_class,
      @col_classes[
        assigns.view_date
        |> Date.beginning_of_month()
        |> Date.day_of_week()
        |> rem(7)
        |> Kernel.+(1)
      ]
    )
  end

  defp build_day_map(date, min, max, disabled_dates) do
    %{date: date, day: date.day, disabled: is_disabled?(date, min, max, disabled_dates)}
  end

  defp is_disabled?(date, min, max, disabled_dates)
       when is_list(disabled_dates) and disabled_dates != [] do
    check_list_and_continue(Enum.member?(disabled_dates, date), date, min, max)
  end

  defp is_disabled?(date, min, max, _dis) when not is_nil(min) and not is_nil(max) do
    Date.compare(date, min) == :lt or Date.compare(date, max) == :gt
  end

  defp is_disabled?(date, min, _max, _dis) when not is_nil(min) do
    Date.compare(date, min) == :lt
  end

  defp is_disabled?(date, _min, max, _dis) when not is_nil(max) do
    Date.compare(date, max) == :gt
  end

  defp is_disabled?(_date, _min, _max, _dis), do: false

  defp check_list_and_continue(true, _date, _min, _max), do: true

  defp check_list_and_continue(false, date, min, max) do
    is_disabled?(date, min, max, nil)
  end
end
