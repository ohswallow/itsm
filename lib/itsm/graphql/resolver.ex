defmodule Itsm.Graphql.Resolver do
  alias Itsm.Posts

  def get_post!(_parent, %{id: id}, %Absinthe.Resolution{}) do
    if Itsm.Utils.is_uuid(id) do
      {:ok, Posts.get_post!(id)}
    else
      {:error, "Invalid ID"}
    end
  end

  def list_posts(_parent, args, resolution) do
    Itsm.Graphql.PagingHelper.paginate(Posts.Post, args, resolution,
      default_columns: get_meta(resolution, :default_columns, []),
      range_columns: get_meta(resolution, :range_columns, [])
    )
  end

  defp get_meta(%Absinthe.Resolution{} = resolution, atom, default) do
    case resolution.definition.schema_node do
      %{__private__: _store} = schema_node -> Absinthe.Type.meta(schema_node, atom) || default
      _ -> default
    end
  end
end
