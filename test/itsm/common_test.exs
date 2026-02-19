defmodule Itsm.CommonTest do
  use Itsm.DataCase

  alias Itsm.CommonCodes

  describe "common_codes" do
    alias Itsm.Common.CommonCode

    import Itsm.CommonCodesFixtures

    @invalid_attrs %{
      code: nil,
      label: nil,
      description: nil,
      group_code: nil,
      sort_order: nil,
      is_active: nil
    }

    test "list_common_codes/0 returns all common_codes" do
      common_codes = common_codes_fixture()
      assert CommonCodes.list_common_codes() == [common_codes]
    end

    test "get_common_codes!/1 returns the common_codes with given id" do
      common_codes = common_codes_fixture()
      assert CommonCodes.get_common_codes!(common_codes.id) == common_codes
    end

    test "create_common_codes/1 with valid data creates a common_codes" do
      valid_attrs = %{
        code: "some code",
        label: "some label",
        description: "some description",
        group_code: "some group_code",
        sort_order: 42,
        is_active: true
      }

      assert {:ok, %CommonCode{} = codes} = CommonCodes.create_common_codes(valid_attrs)
      assert codes.code == "some code"
      assert codes.label == "some label"
      assert codes.description == "some description"
      assert codes.group_code == "some group_code"
      assert codes.sort_order == 42
      assert codes.is_active == true
    end

    test "create_common_codes/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = CommonCodes.create_common_codes(@invalid_attrs)
    end

    test "update_common_codes/2 with valid data updates the common_codes" do
      common_codes = common_codes_fixture()

      update_attrs = %{
        code: "some updated code",
        label: "some updated label",
        description: "some updated description",
        group_code: "some updated group_code",
        sort_order: 43,
        is_active: false
      }

      assert {:ok, %CommonCode{} = codes} =
               CommonCodes.update_common_codes(common_codes, update_attrs)

      assert codes.code == "some updated code"
      assert codes.label == "some updated label"
      assert codes.description == "some updated description"
      assert codes.group_code == "some updated group_code"
      assert codes.sort_order == 43
      assert codes.is_active == false
    end

    test "update_common_codes/2 with invalid data returns error changeset" do
      common_codes = common_codes_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CommonCodes.update_common_codes(common_codes, @invalid_attrs)

      assert common_codes == CommonCodes.get_common_codes!(common_codes.id)
    end

    test "delete_common_codes/1 deletes the common_codes" do
      common_codes = common_codes_fixture()
      assert {:ok, %CommonCode{}} = CommonCodes.delete_common_codes(common_codes)
      assert_raise Ecto.NoResultsError, fn -> CommonCodes.get_common_codes!(common_codes.id) end
    end

    test "change_common_codes/1 returns a common_codes changeset" do
      common_codes = common_codes_fixture()
      assert %Ecto.Changeset{} = CommonCodes.change_common_codes(common_codes)
    end
  end
end
