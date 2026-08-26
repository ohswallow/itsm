defmodule Itsm.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Itsm.Repo

  alias Itsm.Accounts.{User, UserToken, UserNotifier, Role, Permission}
  alias Itsm.Crews.{Crew, CrewsUsers}

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_employee_number(employee_number) when is_binary(employee_number) do
    Repo.get_by(User, employee_number: employee_number)
  end

  def get_user_by_employee_number_and_password(employee_number, password)
      when is_binary(employee_number) and is_binary(password) do
    user = Repo.get_by(User, employee_number: employee_number)
    if User.valid_password?(user, password), do: user
  end

  def get_user(id) when id in ["", nil], do: %User{}

  def get_user(id), do: Repo.get(User, id)

  def get_users(ids) when is_list(ids) do
    User
    |> where([u], u.id in ^ids)
    |> Repo.all()
  end

  def get_user!(id), do: Repo.get!(User, id)

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {user, :register_user, user})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def register_user(%User{} = action_user, attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :register_user, user})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    Repo.one(query)
    |> case do
      nil ->
        nil

      {%User{} = user, authenticated_at} ->
        user = Repo.preload(user, roles: :permissions)
        {user, authenticated_at}
    end
  end

  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  @spec live_select_by_name(
          user :: User.t(),
          keyword :: String.t(),
          opt :: [{:exclude_crew, Crew.t()}]
        ) :: [map()]
  def live_select_by_name(%User{} = user, keyword, opt \\ []) do
    User
    |> search_by(keyword)
    |> exclude_crew(opt)
    |> where([u], u.organization_code == ^user.organization_code)
    |> where([u], u.department_code == ^user.department_code)
    |> order_by(:display_name)
    |> select([u], %{
      value: u.id,
      label: u.display_name,
      tag_label: fragment("? || '(' || ? || ')'", u.display_name, u.employee_number),
      email: u.email,
      organization: u.organization,
      employee_number: u.employee_number,
      department: u.department
    })
    |> Repo.all()
  end

  defp exclude_crew(query, exclude_crew: crew) do
    crew_member_query =
      CrewsUsers
      |> where([cu], cu.crew_id == ^crew.id)
      |> select([cu], cu.user_id)

    where(query, [u], u.id not in subquery(crew_member_query))
  end

  defp exclude_crew(query, _), do: query

  defp search_by(query, keyword) when keyword in ["", nil], do: query

  defp search_by(query, keyword) do
    where(query, [c], ilike(c.display_name, ^"%#{keyword}%"))
  end

  def crew_ids_names(user) do
    user
    |> Ecto.assoc(:crews)
    |> order_by(:name)
    |> select([c], {c.name, c.id})
    |> Repo.all()
  end

  def list_organization_options do
    from(u in User,
      select: {u.organization, u.organization_code},
      distinct: true,
      where: not is_nil(u.organization) and u.organization != "",
      order_by: [asc: u.organization]
    )
    |> Repo.all()
  end

  def list_users, do: Repo.all(User)

  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {user, :create_user, user})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_user(%User{} = action_user, attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_user, user})
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_user(%User{} = action_user, %User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_user, user}, id: user.id)
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def get_select_options() do
    User
    |> select([c], {c.display_name, c.id})
    |> Repo.all()
  end

  def get_role!(id), do: Repo.get!(Role, id)

  def list_roles, do: Repo.all(Role)

  def create_role(%User{} = action_user, attrs) do
    %Role{}
    |> Role.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, role} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_role, role})
        {:ok, role}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_role(%User{} = action_user, %Role{} = role, attrs) do
    role
    |> Role.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, role} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_role, role}, id: role.id)
        {:ok, role}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_role(%User{} = action_user, %{"id" => id}) do
    get_role!(id)
    |> Repo.delete()
    |> case do
      {:ok, role} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_role, role}, id: role.id)
        {:ok, role}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_role(%Role{} = role, attrs \\ %{}) do
    Role.changeset(role, attrs)
  end

  def get_permission!(id), do: Repo.get!(Permission, id)

  def list_permissions, do: Repo.all(Permission)

  def create_permission(%User{} = action_user, attrs) do
    %Permission{}
    |> Permission.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, permission} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :create_permission, permission})
        {:ok, permission}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def update_permission(%User{} = action_user, %Permission{} = permission, attrs) do
    permission
    |> Permission.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, permission} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :update_permission, permission},
          id: permission.id
        )

        {:ok, permission}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_permission(%User{} = action_user, %{"id" => id}) do
    get_permission!(id)
    |> Repo.delete()
    |> case do
      {:ok, permission} ->
        Itsm.PubSub.Helper.broadcast(__MODULE__, {action_user, :delete_permission, permission},
          id: permission.id
        )

        {:ok, permission}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def change_permission(%Permission{} = permission, attrs \\ %{}) do
    Permission.changeset(permission, attrs)
  end
end
