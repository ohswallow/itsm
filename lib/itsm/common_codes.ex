defmodule Itsm.CommonCodes do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Common.CommonCode

  def list_common_codes_by_group(group_code) do
    CommonCode
    |> with_type(group_code)
    |> is_active(true)
    |> order_by([c], asc: c.sort_order)
    |> Repo.all()
  end

  def get_select_options(group_code) do
    CommonCode
    |> with_type(group_code)
    |> is_active(true)
    |> order_by([c], asc: c.sort_order)
    |> select([c], {c.label, c.code})
    |> Repo.all()
  end

  def get_label(code) do
    CommonCode
    |> where([c], c.code == ^code)
    |> select([c], c.label)
    |> Repo.one()
  end

  defp with_type(query, group_code) when group_code in [nil, ""], do: query

  defp with_type(query, group_code), do: where(query, [c], c.group_code == ^group_code)

  # defp is_active(query, is_active) when is_active in [nil], do: query

  defp is_active(query, is_active), do: where(query, [c], c.is_active == ^is_active)
end
