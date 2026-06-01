defmodule Itsm.OsInstancesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.OsInstances` context.
  """
  alias Itsm.Accounts.User

  @doc """
  Generate a os_instance.
  """
  def os_instance_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        cpu_core: 42,
        hostname: "some hostname",
        ip: "some ip",
        memory_gb: 42,
        os_type: :linux,
        os_version: "some os_version"
      })

    {:ok, os_instance} = Itsm.OsInstances.create_os_instance(%User{}, attrs)

    os_instance
  end
end
