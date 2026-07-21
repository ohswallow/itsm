defmodule Itsm.Graphql.ContentTypes do
  use Absinthe.Schema.Notation

  import Itsm.Graphql.Macros

  object :paging_results do
    field :total_pages, :integer
    field :total_count, :integer
  end

  object :post do
    field :id, :id
    field :metadata, :map
    field :title, :string
    field :content, :string
    field :inserted_at, :string
    field :board, :board
  end

  object :board do
    field :name, :string
    field :description, :string
    field :metadata, :map
    field :slug, :string
  end

  paginated_object(:paginated_posts, :post)

  scalar :map, description: "동적 JSON/Map 데이터를 위한 커스텀 스칼라" do
    parse(fn
      %Absinthe.Blueprint.Input.String{value: value} ->
        Jason.decode(value)

      %Absinthe.Blueprint.Input.Null{} ->
        {:ok, nil}

      _ ->
        :error
    end)

    serialize(& &1)
  end
end
