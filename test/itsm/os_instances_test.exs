defmodule Itsm.OsInstancesTest do
  use Itsm.DataCase

  alias Itsm.OsInstances

  describe "os_instances" do
    alias Itsm.OsInstances.OsInstance

    import Itsm.OsInstancesFixtures

    @invalid_attrs %{os_type: nil, os_version: nil, ip: nil, hostname: nil, cpu_core: nil, memory_gb: nil}

    test "list_os_instances/0 returns all os_instances" do
      os_instance = os_instance_fixture()
      assert OsInstances.list_os_instances() == [os_instance]
    end

    test "get_os_instance!/1 returns the os_instance with given id" do
      os_instance = os_instance_fixture()
      assert OsInstances.get_os_instance!(os_instance.id) == os_instance
    end

    test "create_os_instance/1 with valid data creates a os_instance" do
      valid_attrs = %{os_type: :linux, os_version: "some os_version", ip: "some ip", hostname: "some hostname", cpu_core: 42, memory_gb: 42}

      assert {:ok, %OsInstance{} = os_instance} = OsInstances.create_os_instance(valid_attrs)
      assert os_instance.os_type == :linux
      assert os_instance.os_version == "some os_version"
      assert os_instance.ip == "some ip"
      assert os_instance.hostname == "some hostname"
      assert os_instance.cpu_core == 42
      assert os_instance.memory_gb == 42
    end

    test "create_os_instance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = OsInstances.create_os_instance(@invalid_attrs)
    end

    test "update_os_instance/2 with valid data updates the os_instance" do
      os_instance = os_instance_fixture()
      update_attrs = %{os_type: :windows, os_version: "some updated os_version", ip: "some updated ip", hostname: "some updated hostname", cpu_core: 43, memory_gb: 43}

      assert {:ok, %OsInstance{} = os_instance} = OsInstances.update_os_instance(os_instance, update_attrs)
      assert os_instance.os_type == :windows
      assert os_instance.os_version == "some updated os_version"
      assert os_instance.ip == "some updated ip"
      assert os_instance.hostname == "some updated hostname"
      assert os_instance.cpu_core == 43
      assert os_instance.memory_gb == 43
    end

    test "update_os_instance/2 with invalid data returns error changeset" do
      os_instance = os_instance_fixture()
      assert {:error, %Ecto.Changeset{}} = OsInstances.update_os_instance(os_instance, @invalid_attrs)
      assert os_instance == OsInstances.get_os_instance!(os_instance.id)
    end

    test "delete_os_instance/1 deletes the os_instance" do
      os_instance = os_instance_fixture()
      assert {:ok, %OsInstance{}} = OsInstances.delete_os_instance(os_instance)
      assert_raise Ecto.NoResultsError, fn -> OsInstances.get_os_instance!(os_instance.id) end
    end

    test "change_os_instance/1 returns a os_instance changeset" do
      os_instance = os_instance_fixture()
      assert %Ecto.Changeset{} = OsInstances.change_os_instance(os_instance)
    end
  end
end
