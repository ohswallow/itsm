defmodule Itsm.Admin.AccountsTest do
  use Itsm.DataCase

  alias Itsm.Admin.Accounts

  describe "users" do
    alias Itsm.Accounts.User

    import Itsm.Admin.AccountsFixtures

    @invalid_attrs %{password: nil, role: nil, organization: nil, email: nil, hashed_password: nil, current_password: nil, confirmed_at: nil, employee_number: nil, display_name: nil, organization_code: nil, department: nil, department_code: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{password: "some password", role: "some role", organization: "some organization", email: "some email", hashed_password: "some hashed_password", current_password: "some current_password", confirmed_at: ~U[2026-04-19 07:59:00Z], employee_number: "some employee_number", display_name: "some display_name", organization_code: "some organization_code", department: "some department", department_code: "some department_code"}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.password == "some password"
      assert user.role == "some role"
      assert user.organization == "some organization"
      assert user.email == "some email"
      assert user.hashed_password == "some hashed_password"
      assert user.current_password == "some current_password"
      assert user.confirmed_at == ~U[2026-04-19 07:59:00Z]
      assert user.employee_number == "some employee_number"
      assert user.display_name == "some display_name"
      assert user.organization_code == "some organization_code"
      assert user.department == "some department"
      assert user.department_code == "some department_code"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{password: "some updated password", role: "some updated role", organization: "some updated organization", email: "some updated email", hashed_password: "some updated hashed_password", current_password: "some updated current_password", confirmed_at: ~U[2026-04-20 07:59:00Z], employee_number: "some updated employee_number", display_name: "some updated display_name", organization_code: "some updated organization_code", department: "some updated department", department_code: "some updated department_code"}

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.password == "some updated password"
      assert user.role == "some updated role"
      assert user.organization == "some updated organization"
      assert user.email == "some updated email"
      assert user.hashed_password == "some updated hashed_password"
      assert user.current_password == "some updated current_password"
      assert user.confirmed_at == ~U[2026-04-20 07:59:00Z]
      assert user.employee_number == "some updated employee_number"
      assert user.display_name == "some updated display_name"
      assert user.organization_code == "some updated organization_code"
      assert user.department == "some updated department"
      assert user.department_code == "some updated department_code"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
