defmodule Itsm.Scim.StorageAdapter do
  @behaviour ExScim.Storage.Adapter

  import Ecto.Query, warn: false

  @impl true
  defdelegate get_user(id, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate list_users(filter, sort, pagination, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate create_user(domain_user, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate update_user(id, domain_user, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate delete_user(id, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate user_exists?(id, scope), to: ExScimEcto.StorageAdapter

  @impl true
  defdelegate get_group(id, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate list_groups(filter, sort, pagination, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate create_group(domain_group, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate update_group(id, domain_group, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate replace_group(id, domain_group, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate delete_group(id, scope), to: ExScimEcto.StorageAdapter
  @impl true
  defdelegate group_exists?(id, scope), to: ExScimEcto.StorageAdapter
  @impl true
  def replace_user(id, domain_user, scope \\ nil) do
    {user_schema, _preloads, lookup_key, _filter_mapping, tenant_key, field_mapping} =
      user_schema()

    with {:ok, existing} <- get_resource_by(&user_schema/0, lookup_key, id, tenant_key, scope) do
      attrs =
        domain_user
        |> map_from_struct()
        |> apply_field_mapping_to_storage(field_mapping)

      changeset = user_schema.changeset(existing, attrs)

      case repo().update(changeset) do
        {:ok, updated} -> {:ok, apply_field_mapping_from_storage(updated, field_mapping)}
        error -> error
      end
    end
  end

  # Private helper functions

  defp repo, do: Application.fetch_env!(:ex_scim, :storage_repo)

  defp user_schema, do: parse_model_config(:user_model)

  defp parse_model_config(config_key) do
    case Application.get_env(:ex_scim, config_key) do
      {model, opts} ->
        {model, Keyword.get(opts, :preload, []), Keyword.get(opts, :lookup_key, :id),
         Keyword.get(opts, :filter_mapping, %{}), Keyword.get(opts, :tenant_key),
         Keyword.get(opts, :field_mapping, %{})}

      model when not is_nil(model) ->
        {model, [], :id, %{}, nil, %{}}

      nil ->
        raise ArgumentError, "Missing configuration for #{inspect(config_key)}"
    end
  end

  defp apply_field_mapping_to_storage(attrs, field_mapping) when map_size(field_mapping) == 0,
    do: attrs

  defp apply_field_mapping_to_storage(attrs, field_mapping) do
    Enum.reduce(field_mapping, attrs, fn {domain_key, {db_key, to_fn, _from_fn}}, acc ->
      case Map.pop(acc, domain_key) do
        {nil, acc} -> acc
        {value, acc} -> Map.put(acc, db_key, to_fn.(value))
      end
    end)
  end

  defp apply_field_mapping_from_storage(record, field_mapping) when map_size(field_mapping) == 0,
    do: record

  defp apply_field_mapping_from_storage(record, field_mapping) do
    map =
      if is_struct(record), do: record |> Map.from_struct() |> Map.drop([:__meta__]), else: record

    Enum.reduce(field_mapping, map, fn {domain_key, {db_key, _to_fn, from_fn}}, acc ->
      case Map.pop(acc, db_key) do
        {nil, acc} -> acc
        {value, acc} -> Map.put(acc, domain_key, from_fn.(value))
      end
    end)
  end

  defp maybe_preload(nil, _repo, _preloads), do: nil
  defp maybe_preload(records, _repo, []), do: records
  defp maybe_preload(records, repo, preloads), do: repo.preload(records, preloads)

  defp get_resource_by(schema_opts_fn, field, value, tenant_key, scope) do
    {resource_schema, associations, _lookup_key, _filter_mapping, _tenant_key, _field_mapping} =
      schema_opts_fn.()

    query = from(r in resource_schema, where: field(r, ^field) == ^value)
    query = apply_tenant_scope(query, tenant_key, scope)

    query
    |> repo().one()
    |> maybe_preload(repo(), associations)
    |> case do
      nil -> {:error, :not_found}
      resource -> {:ok, resource}
    end
  end

  defp apply_tenant_scope(query, _tenant_key, nil), do: query
  defp apply_tenant_scope(query, nil, _scope), do: query
  defp apply_tenant_scope(query, _tenant_key, %ExScim.Scope{tenant_id: nil}), do: query

  defp apply_tenant_scope(query, tenant_key, %ExScim.Scope{tenant_id: tenant_id}) do
    where(query, [r], field(r, ^tenant_key) == ^tenant_id)
  end

  defp map_from_struct(struct) when is_struct(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:__meta__])
    |> drop_nils()
  end

  defp map_from_struct(list) when is_list(list), do: Enum.map(list, &map_from_struct/1)

  defp map_from_struct(map), do: map

  defp drop_nils(map) do
    map |> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()
  end
end
