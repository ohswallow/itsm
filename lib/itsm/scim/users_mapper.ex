defmodule Itsm.Scim.UsersMapper do
  use ExScim.Users.Mapper.Adapter

  @scim_core_schema "urn:ietf:params:scim:schemas:core:2.0:User"
  @scim_enterprise_schema "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"

  @impl true
  def from_scim(scim_data, _caller) do
    {:ok,
     %{
       id: scim_data["id"],
       external_id: scim_data["externalId"],
       user_name: scim_data["userName"],
       active: Map.get(scim_data, "active", true),
       name: scim_data["name"],
       display_name: scim_data["displayName"],
       emails: scim_data["emails"] || [],
       schemas: scim_data["schemas"] || [@scim_core_schema],
       meta_created: parse_datetime(get_in(scim_data, ["meta", "created"])),
       meta_last_modified: parse_datetime(get_in(scim_data, ["meta", "lastModified"]))
     }}
  end

  @impl true
  def to_scim(user, _caller, opts \\ []) do
    enterprise_ext = format_enterprise_extension(user)

    schemas =
      if enterprise_ext == %{} do
        [@scim_core_schema]
      else
        [@scim_core_schema, @scim_enterprise_schema]
      end

    scim_data =
      %{
        "schemas" => Map.get(user, :schemas, schemas),
        "id" => Map.get(user, :id),
        "externalId" => Map.get(user, :external_id),
        "userName" => Map.get(user, :user_name),
        "active" => Map.get(user, :active, true),
        "name" => Map.get(user, :name),
        "displayName" => Map.get(user, :display_name),
        "emails" => Map.get(user, :emails, []),
        "meta" => format_meta(user, opts),
        "groups" => format_groups(user)
      }
      |> maybe_put_enterprise_extension(enterprise_ext)
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == [] or v == %{} end)
      |> Map.new()

    {:ok, scim_data}
  end

  defp format_enterprise_extension(user) do
    %{
      "employeeNumber" => Map.get(user, :employee_number),
      "organization" => Map.get(user, :organization),
      "organizationCode" => Map.get(user, :organization_code),
      "department" => Map.get(user, :department),
      "departmentCode" => Map.get(user, :department_code),
      "userStatus" => Map.get(user, :user_status),
      "attributes" => Map.get(user, :attributes),
      "manager" => Map.get(user, :manager),
      "costCenter" => Map.get(user, :cost_center),
      "division" => Map.get(user, :division),
      "site" => Map.get(user, :site),
      "location" => Map.get(user, :location),
      "startdate" => Map.get(user, :startdate),
      "enddate" => Map.get(user, :enddate)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == [] or v == %{} end)
    |> Map.new()
  end

  defp maybe_put_enterprise_extension(scim_data, enterprise_ext) when enterprise_ext == %{} do
    scim_data
  end

  defp maybe_put_enterprise_extension(scim_data, enterprise_ext) do
    Map.put(scim_data, @scim_enterprise_schema, enterprise_ext)
  end

  defp format_groups(%{groups: groups}) when is_list(groups) do
    Enum.map(groups, fn group ->
      %{
        "value" => group.id,
        "display" => group.display_name,
        "type" => "Group",
        "$ref" => "#{ItsmWeb.Endpoint.url()}/scim/v2/Groups/#{group.id}"
      }
    end)
  end

  defp format_groups(%{groups: %Ecto.Association.NotLoaded{}}), do: []
  defp format_groups(_group), do: []
end
