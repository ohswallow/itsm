defmodule Itsm.Admin.Accounts do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Accounts.User

  def list_users do
    Repo.all(User)
  end

  def get_select_options() do
    User
    |> select([c], {c.display_name, c.id})
    |> Repo.all()
  end
end
