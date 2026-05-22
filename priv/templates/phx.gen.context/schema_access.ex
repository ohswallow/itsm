  alias Itsm.Accounts.User
  alias <%= inspect schema.module %>

  defdelegate get_<%= schema.singular %>!(id), to: Itsm.<%= inspect context.alias %>

  defdelegate list_<%= schema.plural %>, to: Itsm.<%= inspect context.alias %>

  defdelegate create_<%= schema.singular %>(action_user, attrs), to: Itsm.<%= inspect context.alias %>

  def update_<%= schema.singular %>(%User{} = action_user, %<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
    |> case do
      {:ok, <%= schema.singular %>} ->
       <%= schema.singular %>.broadcast(__MODULE__, {action_user, :update_<%= schema.singular %>, <%= schema.singular %>}, id: <%= schema.singular %>.id)
       {:ok, <%= schema.singular %>}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defdelegate delete_<%= schema.singular %>(action_user, attrs), to: Itsm.<%= inspect context.alias %>

  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs \\ %{}) do
    <%= inspect schema.alias %>.changeset(<%= schema.singular %>, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end
