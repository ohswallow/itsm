defmodule Itsm.Scim.GroupsMapper do
  use ExScim.Groups.Mapper.Adapter

  @scim_group_schema "urn:ietf:params:scim:schemas:core:2.0:Group"

  @impl true
  def from_scim(scim_data, _caller) do
    ExScimPhoenix.Controller.GroupController

    {:ok,
     %{
       id: scim_data["id"],
       external_id: scim_data["externalId"],
       display_name: scim_data["displayName"],
       members: scim_data["members"] || [],
       schemas: scim_data["schemas"] || [@scim_group_schema],
       meta_created: parse_datetime(get_in(scim_data, ["meta", "created"])),
       meta_last_modified: parse_datetime(get_in(scim_data, ["meta", "lastModified"]))
     }}
  end

  @impl true
  def to_scim(group, _caller, opts \\ []) do
    scim_data =
      %{
        "schemas" => Map.get(group, :schemas, [@scim_group_schema]),
        "id" => Map.get(group, :id),
        "externalId" => Map.get(group, :external_id),
        "displayName" => Map.get(group, :display_name),
        "members" => format_members(group),
        "meta" => format_meta(group, opts)
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    {:ok, scim_data}
  end

  defp format_members(%{members: members}) when is_list(members) do
    Enum.map(members, fn user ->
      %{
        "value" => user.id,
        "display" => user.display_name,
        "type" => "User",
        "$ref" => "#{ItsmWeb.Endpoint.url()}/scim/v2/Users/#{user.id}"
      }
    end)
  end

  defp format_members(%{members: %Ecto.Association.NotLoaded{}}), do: []
  defp format_members(_group), do: []
end
