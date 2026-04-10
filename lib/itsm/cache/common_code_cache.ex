defmodule Itsm.CommonCodeCache do
  use GenServer

  alias Itsm.Repo
  alias Itsm.Common.CommonCode
  alias Itsm.CommonCodes

  @table :common_code_cache

  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])

    Itsm.Utils.subscribes(CommonCodes)

    send(self(), :load_from_db)
    {:ok, %{}}
  end

  def handle_info(:load_from_db, state) do
    do_load()
    {:noreply, state}
  end

  def handle_info({:pubsub, {_acction_user, _event, _item}}, state) do
    do_load()
    {:noreply, state}
  end

  def handle_info(_event, state) do
    {:noreply, state}
  end

  def handle_cast(:load_from_db, state) do
    do_load()
    {:noreply, state}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def reload, do: GenServer.cast(__MODULE__, :load_from_db)

  def get_by_group(group_code) do
    @table
    |> :ets.match_object({{group_code, :_}, :_})
    |> Enum.filter(fn {_, data} -> data.is_active end)
    |> Enum.map(fn {_, data} -> data end)
    |> Enum.sort_by(& &1.sort_order)
  end

  def get_label(group_code, code) do
    case :ets.lookup(@table, {group_code, code}) do
      [{_, data}] -> data.label
      [] -> code
    end
  end

  def get_select_options(group_code) do
    get_by_group(group_code)
    |> Enum.map(fn item ->
      {item.label, item.code}
    end)
  end

  defp do_load do
    data_list =
      CommonCode
      |> Repo.all()
      |> Enum.map(fn item -> {{item.group_code, item.code}, item} end)

    :ets.delete_all_objects(@table)

    :ets.insert(@table, data_list)

    update_map =
      data_list
      |> Enum.into(%{}, fn {{group, code}, item} -> {"#{group}:#{code}", item.label} end)

    ItsmWeb.Endpoint.broadcast_from(self(), "common_code:updates", "all_codes_reload", update_map)

    IO.puts("✅ [CodeCache] #{DateTime.utc_now()} - 공통코드 로드 완료 (Count: #{length(data_list)})")
  end
end
