defmodule Itsm.Admin.CommonCodes do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Common.CommonCode

  def get_common_code!(id), do: Repo.get!(CommonCode, id)

  def change_common_code(%CommonCode{} = common_code, attrs \\ %{}) do
    CommonCode.changeset(common_code, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def create_common_code(%User{} = action_user, attrs \\ %{}) do
    %CommonCode{}
    |> CommonCode.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, common_code} ->
        event = :create_common_code
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, common_code})
        {:ok, common_code}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_common_code(%User{} = action_user, %CommonCode{} = common_code, attrs) do
    common_code
    |> CommonCode.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, common_code} ->
        event = :update_common_code

        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, common_code},
          id: common_code.id
        )

        {:ok, common_code}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_common_code(%User{} = action_user, %{"id" => id}) do
    Repo.delete(get_common_code!(id))
    |> case do
      {:ok, common_code} ->
        event = :delete_common_code

        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, common_code},
          id: common_code.id
        )

        {:ok, common_code}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate get_select_options(group_code), to: Itsm.CommonCodeCache

  defdelegate get_label(group_code, code), to: Itsm.CommonCodeCache
end
