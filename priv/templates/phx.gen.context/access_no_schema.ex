  alias <%= inspect schema.module %>

  def get_<%= schema.singular %>!(id), do: Repo.get!(<%= inspect schema.alias %>, id)

  def list_<%= schema.plural %>, do: Repo.all(<%= inspect schema.alias %>)

  def create_<%= schema.singular %>(attrs \\ %{}) do
    %<%= inspect schema.alias %>{}
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, <%= schema.singular %>} ->
       Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :create_<%= schema.singular %>, <%= schema.singular %>})
       {:ok, <%= schema.singular %>}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, <%= schema.singular %>} ->
       Itsm.Utils.broadcast(__MODULE__, {attrs["current_user"], :update_<%= schema.singular %>, <%= schema.singular %>})
       Itsm.Utils.broadcasts(__MODULE__, {attrs["current_user"], :update_<%= schema.singular %>, <%= schema.singular %>})
       {:ok, <%= schema.singular %>}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_<%= schema.singular %>(%{"id" => id} = attrs) do
    Repo.delete(get_<%= schema.singular %>!(id))
    |> case do
       {:ok, <%= schema.singular %>} ->
        Itsm.Utils.broadcast(<%= inspect schema.alias %>, {attrs["current_user"], :delete_<%= schema.singular %>, <%= schema.singular %>})
        Itsm.Utils.broadcasts(<%= inspect schema.alias %>, {attrs["current_user"], :delete_<%= schema.singular %>, <%= schema.singular %>})
        {:ok, <%= schema.singular %>}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs \\ %{}) do
    <%= inspect schema.alias %>.changeset(<%= schema.singular %>, attrs)
  end
