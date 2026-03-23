  alias <%= inspect schema.module %>

  def get_<%= schema.singular %>!(id), do: Repo.get!(<%= inspect schema.alias %>, id)

  def list_<%= schema.plural %>, do: Repo.all(<%= inspect schema.alias %>)

  def create_<%= schema.singular %>(attrs \\ %{}) do
    %<%= inspect schema.alias %>{}
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, <%= schema.singular %>} ->
       Itsm.Utils.broadcasts(:<%= schema.plural %>, {:create_<%= schema.singular %>, <%= schema.singular %>})
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
       Itsm.Utils.broadcast(:<%= schema.singular %>, {:update_<%= schema.singular %>, <%= schema.singular %>})
       Itsm.Utils.broadcasts(:<%= schema.plural %>, {:update_<%= schema.singular %>, <%= schema.singular %>})
       {:ok, <%= schema.singular %>}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>) do
    Repo.delete(<%= schema.singular %>)
    |> case do
      {:ok, <%= schema.singular %>} ->
       Itsm.Utils.broadcast(:<%= schema.singular %>, {:update_<%= schema.singular %>, <%= schema.singular %>})
       Itsm.Utils.broadcasts(:<%= schema.plural %>, {:update_<%= schema.singular %>, <%= schema.singular %>})
       {:ok, <%= schema.singular %>}

      {:error, _} = error ->
        error
    end
  end

  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs \\ %{}) do
    <%= inspect schema.alias %>.changeset(<%= schema.singular %>, attrs)
  end
