defmodule Itsm.Admin.CommonCodes do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Common.CommonCode

  def get_common_code!(id), do: Repo.get!(CommonCode, id)

  def change_common_code(%CommonCode{} = common_code, attrs \\ %{}) do
    CommonCode.changeset(common_code, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def create_common_code(attrs \\ %{}) do
    %CommonCode{}
    |> CommonCode.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, common_code} ->
        Itsm.Utils.broadcasts(:common_code, {:create_common_code, common_code})
        {:ok, common_code}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_common_code(%CommonCode{} = common_code, attrs) do
    common_code
    |> CommonCode.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, common_code} ->
        Itsm.Utils.broadcast(:common_code, {:update_common_code, common_code})
        Itsm.Utils.broadcasts(:common_codes, {:update_common_code, common_code})
        {:ok, common_code}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_common_code(%CommonCode{} = common_code) do
    Repo.delete(common_code)
    |> case do
      {:ok, common_code} ->
        Itsm.Utils.broadcast(:common_code, {:delete_common_code, common_code})
        Itsm.Utils.broadcasts(:common_codes, {:delete_common_code, common_code})
        {:ok, common_code}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate get_select_options(group_code), to: Itsm.CommonCodes
end
