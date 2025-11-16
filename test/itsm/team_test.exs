defmodule Itsm.TeamTest do
  use Itsm.DataCase

  alias Itsm.Team

  describe "crews" do
    alias Itsm.Team.Crew

    import Itsm.TeamFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_crews/0 returns all crews" do
      crew = crew_fixture()
      assert Team.list_crews() == [crew]
    end

    test "get_crew!/1 returns the crew with given id" do
      crew = crew_fixture()
      assert Team.get_crew!(crew.id) == crew
    end

    test "create_crew/1 with valid data creates a crew" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Crew{} = crew} = Team.create_crew(valid_attrs)
      assert crew.name == "some name"
      assert crew.description == "some description"
    end

    test "create_crew/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Team.create_crew(@invalid_attrs)
    end

    test "update_crew/2 with valid data updates the crew" do
      crew = crew_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Crew{} = crew} = Team.update_crew(crew, update_attrs)
      assert crew.name == "some updated name"
      assert crew.description == "some updated description"
    end

    test "update_crew/2 with invalid data returns error changeset" do
      crew = crew_fixture()
      assert {:error, %Ecto.Changeset{}} = Team.update_crew(crew, @invalid_attrs)
      assert crew == Team.get_crew!(crew.id)
    end

    test "delete_crew/1 deletes the crew" do
      crew = crew_fixture()
      assert {:ok, %Crew{}} = Team.delete_crew(crew)
      assert_raise Ecto.NoResultsError, fn -> Team.get_crew!(crew.id) end
    end

    test "change_crew/1 returns a crew changeset" do
      crew = crew_fixture()
      assert %Ecto.Changeset{} = Team.change_crew(crew)
    end
  end

  describe "members" do
    alias Itsm.Team.Member

    import Itsm.TeamFixtures

    @invalid_attrs %{}

    test "list_members/0 returns all members" do
      member = member_fixture()
      assert Team.list_members() == [member]
    end

    test "get_member!/1 returns the member with given id" do
      member = member_fixture()
      assert Team.get_member!(member.id) == member
    end

    test "create_member/1 with valid data creates a member" do
      valid_attrs = %{}

      assert {:ok, %Member{} = member} = Team.create_member(valid_attrs)
    end

    test "create_member/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Team.create_member(@invalid_attrs)
    end

    test "update_member/2 with valid data updates the member" do
      member = member_fixture()
      update_attrs = %{}

      assert {:ok, %Member{} = member} = Team.update_member(member, update_attrs)
    end

    test "update_member/2 with invalid data returns error changeset" do
      member = member_fixture()
      assert {:error, %Ecto.Changeset{}} = Team.update_member(member, @invalid_attrs)
      assert member == Team.get_member!(member.id)
    end

    test "delete_member/1 deletes the member" do
      member = member_fixture()
      assert {:ok, %Member{}} = Team.delete_member(member)
      assert_raise Ecto.NoResultsError, fn -> Team.get_member!(member.id) end
    end

    test "change_member/1 returns a member changeset" do
      member = member_fixture()
      assert %Ecto.Changeset{} = Team.change_member(member)
    end
  end
end
