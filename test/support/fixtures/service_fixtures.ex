defmodule Itsm.ServiceFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.Service` context.
  """
  alias Itsm.Accounts.User

  @doc """
  Generate a unique category name.
  """
  def unique_category_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        active: true,
        affiliate: :A0,
        description: "some description",
        group: "some group",
        name: unique_category_name(),
        request_name: "some request_name"
      })

    {:ok, category} = Itsm.Admin.Categories.create_category(%User{}, attrs)

    category
  end

  # @doc """
  # Generate a request.
  # """

  # def request_fixture(attrs \\ %{}) do

  #   {:ok, request} =
  #     attrs
  #     |> Enum.into(%{
  #       common_k_create_vms: %{},
  #       description: "some description",
  #       due_date: ~D[2025-09-28],
  #       env: :prod,
  #       title: "some title"
  #     })
  #     |> Itsm.Service.create_request()

  #   request
  # end

  @doc """
  Generate a approval.
  """
  def approval_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        approver_id: "some approver_id",
        approver_name: "some approver_name",
        opnion: "some opnion",
        status: :request
      })

    {:ok, approval} = Itsm.Approvals.create_approval(%User{}, attrs)

    approval
  end
end
