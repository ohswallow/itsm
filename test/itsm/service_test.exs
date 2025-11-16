defmodule Itsm.ServiceTest do
  use Itsm.DataCase

  alias Itsm.Service

  describe "categories" do
    alias Itsm.Service.Category

    import Itsm.ServiceFixtures

    @invalid_attrs %{
      active: nil,
      name: nil,
      description: nil,
      group: nil,
      affiliate: nil,
      request_name: nil
    }

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Service.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Service.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{
        active: true,
        name: "some name",
        description: "some description",
        group: "some group",
        affiliate: :A0,
        request_name: "some request_name"
      }

      assert {:ok, %Category{} = category} = Service.create_category(valid_attrs)
      assert category.active == true
      assert category.name == "some name"
      assert category.description == "some description"
      assert category.group == "some group"
      assert category.affiliate == :A0
      assert category.request_name == "some request_name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Service.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()

      update_attrs = %{
        active: false,
        name: "some updated name",
        description: "some updated description",
        group: "some updated group",
        affiliate: :B0,
        request_name: "some updated request_name"
      }

      assert {:ok, %Category{} = category} = Service.update_category(category, update_attrs)
      assert category.active == false
      assert category.name == "some updated name"
      assert category.description == "some updated description"
      assert category.group == "some updated group"
      assert category.affiliate == :B0
      assert category.request_name == "some updated request_name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Service.update_category(category, @invalid_attrs)
      assert category == Service.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Service.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Service.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Service.change_category(category)
    end
  end

  describe "requests" do
    alias Itsm.Service.Request

    import Itsm.ServiceFixtures

    @invalid_attrs %{
      env: nil,
      description: nil,
      title: nil,
      due_date: nil,
      common_k_create_vms: nil
    }

    test "list_requests/0 returns all requests" do
      request = request_fixture()
      assert Service.list_requests() == [request]
    end

    test "get_request!/1 returns the request with given id" do
      request = request_fixture()
      assert Service.get_request!(request.id) == request
    end

    test "create_request/1 with valid data creates a request" do
      valid_attrs = %{
        env: :prod,
        description: "some description",
        title: "some title",
        due_date: ~D[2025-09-28],
        common_k_create_vms: %{}
      }

      assert {:ok, %Request{} = request} = Service.create_request(valid_attrs)
      assert request.env == :prod
      assert request.description == "some description"
      assert request.title == "some title"
      assert request.due_date == ~D[2025-09-28]
      assert request.common_k_create_vms == %{}
    end

    test "create_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Service.create_request(@invalid_attrs)
    end

    test "update_request/2 with valid data updates the request" do
      request = request_fixture()

      update_attrs = %{
        env: :stg,
        description: "some updated description",
        title: "some updated title",
        due_date: ~D[2025-09-29],
        common_k_create_vms: %{}
      }

      assert {:ok, %Request{} = request} = Service.update_request(request, update_attrs)
      assert request.env == :stg
      assert request.description == "some updated description"
      assert request.title == "some updated title"
      assert request.due_date == ~D[2025-09-29]
      assert request.common_k_create_vms == %{}
    end

    test "update_request/2 with invalid data returns error changeset" do
      request = request_fixture()
      assert {:error, %Ecto.Changeset{}} = Service.update_request(request, @invalid_attrs)
      assert request == Service.get_request!(request.id)
    end

    test "delete_request/1 deletes the request" do
      request = request_fixture()
      assert {:ok, %Request{}} = Service.delete_request(request)
      assert_raise Ecto.NoResultsError, fn -> Service.get_request!(request.id) end
    end

    test "change_request/1 returns a request changeset" do
      request = request_fixture()
      assert %Ecto.Changeset{} = Service.change_request(request)
    end
  end

  describe "approvals" do
    alias Itsm.Service.Approval

    import Itsm.ServiceFixtures

    @invalid_attrs %{status: nil, approver_id: nil, approver_name: nil, opnion: nil, approved_at: nil}

    test "list_approvals/0 returns all approvals" do
      approval = approval_fixture()
      assert Service.list_approvals() == [approval]
    end

    test "get_approval!/1 returns the approval with given id" do
      approval = approval_fixture()
      assert Service.get_approval!(approval.id) == approval
    end

    test "create_approval/1 with valid data creates a approval" do
      valid_attrs = %{status: :request, approver_id: "some approver_id", approver_name: "some approver_name", opnion: "some opnion", approved_at: ~U[2025-10-09 10:41:00Z]}

      assert {:ok, %Approval{} = approval} = Service.create_approval(valid_attrs)
      assert approval.status == :request
      assert approval.approver_id == "some approver_id"
      assert approval.approver_name == "some approver_name"
      assert approval.opnion == "some opnion"
      assert approval.approved_at == ~U[2025-10-09 10:41:00Z]
    end

    test "create_approval/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Service.create_approval(@invalid_attrs)
    end

    test "update_approval/2 with valid data updates the approval" do
      approval = approval_fixture()
      update_attrs = %{status: :check, approver_id: "some updated approver_id", approver_name: "some updated approver_name", opnion: "some updated opnion", approved_at: ~U[2025-10-10 10:41:00Z]}

      assert {:ok, %Approval{} = approval} = Service.update_approval(approval, update_attrs)
      assert approval.status == :check
      assert approval.approver_id == "some updated approver_id"
      assert approval.approver_name == "some updated approver_name"
      assert approval.opnion == "some updated opnion"
      assert approval.approved_at == ~U[2025-10-10 10:41:00Z]
    end

    test "update_approval/2 with invalid data returns error changeset" do
      approval = approval_fixture()
      assert {:error, %Ecto.Changeset{}} = Service.update_approval(approval, @invalid_attrs)
      assert approval == Service.get_approval!(approval.id)
    end

    test "delete_approval/1 deletes the approval" do
      approval = approval_fixture()
      assert {:ok, %Approval{}} = Service.delete_approval(approval)
      assert_raise Ecto.NoResultsError, fn -> Service.get_approval!(approval.id) end
    end

    test "change_approval/1 returns a approval changeset" do
      approval = approval_fixture()
      assert %Ecto.Changeset{} = Service.change_approval(approval)
    end
  end
end
