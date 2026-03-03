defmodule Itsm.OsInstancesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Itsm.OsInstances` context.
  """

  @doc """
  Generate a os_instance.
  """
  def os_instance_fixture(attrs \\ %{}) do
    {:ok, os_instance} =
      attrs
      |> Enum.into(%{
        cpu_core: 42,
        hostname: "some hostname",
        ip: "some ip",
        memory_gb: 42,
        os_type: :linux,
        os_version: "some os_version"
      })
      |> Itsm.OsInstances.create_os_instance()

    os_instance
  end
end
