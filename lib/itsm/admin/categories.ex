defmodule Itsm.Admin.Categories do
  import Ecto.Query, warn: false
  alias Itsm.Accounts.User
  alias Itsm.Repo
  alias Itsm.Service.Category

  def get_category!(id), do: Repo.get!(Category, id)

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.admin_changeset(category, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end

  def create_category(%User{} = action_user, attrs) do
    %Category{}
    |> Category.admin_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, category} ->
        event = :create_category
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, category})
        {:ok, category}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_category(%User{} = action_user, %Category{} = category, attrs) do
    category
    |> Category.admin_changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, category} ->
        event = :update_category
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, category}, id: category.id)

        {:ok, category}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_category(%User{} = action_user, %{"id" => id}) do
    get_category!(id)
    |> Repo.delete()
    |> case do
      {:ok, category} ->
        event = :delete_category
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, event, category}, id: category.id)
        {:ok, category}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_category_options do
    Category
    |> select([c], {c.name, c.id})
    |> Repo.all()
  end
end
