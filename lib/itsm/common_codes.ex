defmodule Itsm.CommonCodes do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Common.CommonCode

  def list_common_codes_by_group(group_code) do
    CommonCode
    |> with_type(group_code)
    |> where([c], c.is_active == true)
    |> order_by([c], asc: c.sort_order)
    |> Repo.all()
  end

  defdelegate get_select_options(group_code), to: Itsm.CommonCodeCache

  defdelegate get_label(group_code, code), to: Itsm.CommonCodeCache

  defp with_type(query, group_code) when group_code in [nil, ""], do: query

  defp with_type(query, group_code), do: where(query, [c], c.group_code == ^group_code)
end
