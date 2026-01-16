defmodule Itsm.ServiceFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Service` context.
  """

  @doc """
  Generate a unique category name.
  """
  def unique_category_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        active: true,
        affiliate: :A0,
        description: "some description",
        group: "some group",
        name: unique_category_name(),
        request_name: "some request_name"
      })
      |> Itsm.Categories.create_category()

    category
  end

  @doc """
  Generate a request.
  """
  def request_fixture(attrs \\ %{}) do
    {:ok, request} =
      attrs
      |> Enum.into(%{
        common_k_create_vms: %{},
        description: "some description",
        due_date: ~D[2025-09-28],
        env: :prod,
        title: "some title"
      })
      |> Itsm.Requests.create_request()

    request
  end

  @doc """
  Generate a approval.
  """
  def approval_fixture(attrs \\ %{}) do
    {:ok, approval} =
      attrs
      |> Enum.into(%{
        approved_at: ~U[2025-10-09 10:41:00Z],
        approver_id: "some approver_id",
        approver_name: "some approver_name",
        opnion: "some opnion",
        status: :request
      })
      |> Itsm.Approvals.create_approval()

    approval
  end
end
