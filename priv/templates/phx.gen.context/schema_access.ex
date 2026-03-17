  alias <%= inspect schema.module %>

  defdelegate get_<%= schema.singular %>!(id), to: Itsm.<%= inspect context.alias %>

  defdelegate list_<%= schema.plural %>, to: Itsm.<%= inspect context.alias %>

  defdelegate create_<%= schema.singular %>(attrs \\ %{}), to: Itsm.<%= inspect context.alias %>

  def update_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs) do
    <%= schema.singular %>
    |> <%= inspect schema.alias %>.changeset(attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
    |> Repo.update()
  end

  defdelegate delete_<%= schema.singular %>(<%= schema.singular %>), to: Itsm.<%= inspect context.alias %>

  def change_<%= schema.singular %>(%<%= inspect schema.alias %>{} = <%= schema.singular %>, attrs \\ %{}) do
    <%= inspect schema.alias %>.changeset(<%= schema.singular %>, attrs)
    |> Itsm.Utils.maybe_put_change(:inserted_at, attrs["inserted_at"])
  end
