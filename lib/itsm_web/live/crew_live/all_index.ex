defmodule ItsmWeb.CrewLive.AllIndex do
  alias Itsm.Crews.Crew
  use ItsmWeb, :live_view

  alias Itsm.Crews

  # 공통 컴포넌트 임포트
  import ItsmWeb.CrewLive.TableComponents
  alias Itsm.Paging

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:crews, [])
     |> assign(:org_options, Itsm.CommonCodes.get_select_options("계열사"))
     |> Itsm.PubSub.Helper.subscribe(Crews)}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :index, params, url) do
    socket
    |> assign_paged_stream(:crews, Crew, params, url)
    |> assign(:page_title, "All Crew")
  end

  defp assign_paged_stream(socket, stream_key, schema, params, url) do
    opts = [
      default_columns: [
        :name,
        :description,
        leader: :display_name,
        leader: :department
      ],
      preloads: [leader: [:organization_code, :department, :display_name]]
    ]

    %{entries: entries, results: results} =
      Paging.search_and_pagination(schema, params, url, opts)

    socket
    |> assign(:results, results)
    |> stream(stream_key, entries, reset: true)
  end

  defp handle_pubsub(_action_user, event, {:crews, _crew}, socket)
       when event in [:create_crew, :update_crew, :delete_crew] do
    %{results: params} = socket.assigns

    {:noreply, push_patch(socket, to: ~p"/crews/all?#{params}")}
  end

  defp handle_pubsub(_action_user, _event, _item, socket) do
    {:noreply, socket}
  end
end
