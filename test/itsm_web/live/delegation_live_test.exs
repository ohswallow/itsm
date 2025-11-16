defmodule ItsmWeb.DelegationLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.DelegationsFixtures

  @create_attrs %{reason: :vacation, delegator_name: "some delegator_name", delegatee_name: "some delegatee_name", start_date: "2025-10-23T01:30:00Z", end_date: "2025-10-23T01:30:00Z"}
  @update_attrs %{reason: :business_trip, delegator_name: "some updated delegator_name", delegatee_name: "some updated delegatee_name", start_date: "2025-10-24T01:30:00Z", end_date: "2025-10-24T01:30:00Z"}
  @invalid_attrs %{reason: nil, delegator_name: nil, delegatee_name: nil, start_date: nil, end_date: nil}

  defp create_delegation(_) do
    delegation = delegation_fixture()
    %{delegation: delegation}
  end

  describe "Index" do
    setup [:create_delegation]

    test "lists all delegations", %{conn: conn, delegation: delegation} do
      {:ok, _index_live, html} = live(conn, ~p"/delegations")

      assert html =~ "Listing Delegations"
      assert html =~ delegation.delegator_name
    end

    test "saves new delegation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/delegations")

      assert index_live |> element("a", "New Delegation") |> render_click() =~
               "New Delegation"

      assert_patch(index_live, ~p"/delegations/new")

      assert index_live
             |> form("#delegation-form", delegation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#delegation-form", delegation: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/delegations")

      html = render(index_live)
      assert html =~ "Delegation created successfully"
      assert html =~ "some delegator_name"
    end

    test "updates delegation in listing", %{conn: conn, delegation: delegation} do
      {:ok, index_live, _html} = live(conn, ~p"/delegations")

      assert index_live |> element("#delegations-#{delegation.id} a", "Edit") |> render_click() =~
               "Edit Delegation"

      assert_patch(index_live, ~p"/delegations/#{delegation}/edit")

      assert index_live
             |> form("#delegation-form", delegation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#delegation-form", delegation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/delegations")

      html = render(index_live)
      assert html =~ "Delegation updated successfully"
      assert html =~ "some updated delegator_name"
    end

    test "deletes delegation in listing", %{conn: conn, delegation: delegation} do
      {:ok, index_live, _html} = live(conn, ~p"/delegations")

      assert index_live |> element("#delegations-#{delegation.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#delegations-#{delegation.id}")
    end
  end

  describe "Show" do
    setup [:create_delegation]

    test "displays delegation", %{conn: conn, delegation: delegation} do
      {:ok, _show_live, html} = live(conn, ~p"/delegations/#{delegation}")

      assert html =~ "Show Delegation"
      assert html =~ delegation.delegator_name
    end

    test "updates delegation within modal", %{conn: conn, delegation: delegation} do
      {:ok, show_live, _html} = live(conn, ~p"/delegations/#{delegation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Delegation"

      assert_patch(show_live, ~p"/delegations/#{delegation}/show/edit")

      assert show_live
             |> form("#delegation-form", delegation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#delegation-form", delegation: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/delegations/#{delegation}")

      html = render(show_live)
      assert html =~ "Delegation updated successfully"
      assert html =~ "some updated delegator_name"
    end
  end
end
