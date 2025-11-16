defmodule Itsm.DelegationsTest do
  use Itsm.DataCase

  alias Itsm.Delegations

  describe "delegations" do
    alias Itsm.Delegations.Delegation

    import Itsm.DelegationsFixtures

    @invalid_attrs %{reason: nil, delegator_name: nil, delegatee_name: nil, start_date: nil, end_date: nil}

    test "list_delegations/0 returns all delegations" do
      delegation = delegation_fixture()
      assert Delegations.list_delegations() == [delegation]
    end

    test "get_delegation!/1 returns the delegation with given id" do
      delegation = delegation_fixture()
      assert Delegations.get_delegation!(delegation.id) == delegation
    end

    test "create_delegation/1 with valid data creates a delegation" do
      valid_attrs = %{reason: :vacation, delegator_name: "some delegator_name", delegatee_name: "some delegatee_name", start_date: ~U[2025-10-23 01:30:00Z], end_date: ~U[2025-10-23 01:30:00Z]}

      assert {:ok, %Delegation{} = delegation} = Delegations.create_delegation(valid_attrs)
      assert delegation.reason == :vacation
      assert delegation.delegator_name == "some delegator_name"
      assert delegation.delegatee_name == "some delegatee_name"
      assert delegation.start_date == ~U[2025-10-23 01:30:00Z]
      assert delegation.end_date == ~U[2025-10-23 01:30:00Z]
    end

    test "create_delegation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Delegations.create_delegation(@invalid_attrs)
    end

    test "update_delegation/2 with valid data updates the delegation" do
      delegation = delegation_fixture()
      update_attrs = %{reason: :business_trip, delegator_name: "some updated delegator_name", delegatee_name: "some updated delegatee_name", start_date: ~U[2025-10-24 01:30:00Z], end_date: ~U[2025-10-24 01:30:00Z]}

      assert {:ok, %Delegation{} = delegation} = Delegations.update_delegation(delegation, update_attrs)
      assert delegation.reason == :business_trip
      assert delegation.delegator_name == "some updated delegator_name"
      assert delegation.delegatee_name == "some updated delegatee_name"
      assert delegation.start_date == ~U[2025-10-24 01:30:00Z]
      assert delegation.end_date == ~U[2025-10-24 01:30:00Z]
    end

    test "update_delegation/2 with invalid data returns error changeset" do
      delegation = delegation_fixture()
      assert {:error, %Ecto.Changeset{}} = Delegations.update_delegation(delegation, @invalid_attrs)
      assert delegation == Delegations.get_delegation!(delegation.id)
    end

    test "delete_delegation/1 deletes the delegation" do
      delegation = delegation_fixture()
      assert {:ok, %Delegation{}} = Delegations.delete_delegation(delegation)
      assert_raise Ecto.NoResultsError, fn -> Delegations.get_delegation!(delegation.id) end
    end

    test "change_delegation/1 returns a delegation changeset" do
      delegation = delegation_fixture()
      assert %Ecto.Changeset{} = Delegations.change_delegation(delegation)
    end
  end
end
