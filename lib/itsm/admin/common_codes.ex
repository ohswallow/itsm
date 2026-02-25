defmodule Itsm.Admin.CommonCodes do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Common.CommonCode

  def list_common_codes do
    Repo.all(CommonCode)
  end

  def get_common_code!(id), do: Repo.get!(CommonCode, id)

  def list_common_codes_group_by_group_code do
    CommonCode
    |> group_by([c], c.group_code)
    |> select([c], %{group_code: c.group_code, count: count(c.id)})
    |> Repo.all()
  end

  def create_common_code(attrs \\ %{}) do
    %CommonCode{}
    |> CommonCode.changeset(attrs)
    |> Repo.insert()
  end

  def update_common_code(%CommonCode{} = common_code, attrs) do
    common_code
    |> CommonCode.changeset(attrs)
    |> Repo.update()
  end

  def delete_common_code(%CommonCode{} = common_code) do
    Repo.delete(common_code)
  end

  def change_common_code(%CommonCode{} = common_code, attrs \\ %{}) do
    CommonCode.changeset(common_code, attrs)
  end

  defdelegate list_common_codes_by_group(group_code), to: Itsm.CommonCodes
  defdelegate get_select_options(group_code), to: Itsm.CommonCodes
  defdelegate get_label(group_code, code), to: Itsm.CommonCodes
end
