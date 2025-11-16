defmodule ItsmWeb.CrewLiveTest do
  use ItsmWeb.ConnCase

  import Phoenix.LiveViewTest
  import Itsm.TeamFixtures

  @create_attrs %{name: "some name", description: "some description"}
  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_crew(_) do
    crew = crew_fixture()
    %{crew: crew}
  end

  describe "Index" do
    setup [:create_crew]

    test "lists all crews", %{conn: conn, crew: crew} do
      {:ok, _index_live, html} = live(conn, ~p"/crews")

      assert html =~ "Listing Crews"
      assert html =~ crew.name
    end

    test "saves new crew", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/crews")

      assert index_live |> element("a", "New Crew") |> render_click() =~
               "New Crew"

      assert_patch(index_live, ~p"/crews/new")

      assert index_live
             |> form("#crew-form", crew: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#crew-form", crew: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/crews")

      html = render(index_live)
      assert html =~ "Crew created successfully"
      assert html =~ "some name"
    end

    test "updates crew in listing", %{conn: conn, crew: crew} do
      {:ok, index_live, _html} = live(conn, ~p"/crews")

      assert index_live |> element("#crews-#{crew.id} a", "Edit") |> render_click() =~
               "Edit Crew"

      assert_patch(index_live, ~p"/crews/#{crew}/edit")

      assert index_live
             |> form("#crew-form", crew: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#crew-form", crew: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/crews")

      html = render(index_live)
      assert html =~ "Crew updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes crew in listing", %{conn: conn, crew: crew} do
      {:ok, index_live, _html} = live(conn, ~p"/crews")

      assert index_live |> element("#crews-#{crew.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#crews-#{crew.id}")
    end
  end

  describe "Show" do
    setup [:create_crew]

    test "displays crew", %{conn: conn, crew: crew} do
      {:ok, _show_live, html} = live(conn, ~p"/crews/#{crew}")

      assert html =~ "Show Crew"
      assert html =~ crew.name
    end

    test "updates crew within modal", %{conn: conn, crew: crew} do
      {:ok, show_live, _html} = live(conn, ~p"/crews/#{crew}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Crew"

      assert_patch(show_live, ~p"/crews/#{crew}/show/edit")

      assert show_live
             |> form("#crew-form", crew: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#crew-form", crew: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/crews/#{crew}")

      html = render(show_live)
      assert html =~ "Crew updated successfully"
      assert html =~ "some updated name"
    end
  end
end
