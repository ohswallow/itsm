defmodule Itsm.Graphql.ContentTypes do
  use Absinthe.Schema.Notation

  object :post do
    field :id, :id
    field :metadata, :map
    field :title, :string
    field :content, :string
  end

  scalar :map, description: "동적 JSON/Map 데이터를 위한 커스텀 스칼라" do
    parse(&{:ok, &1})

    serialize(& &1)
  end
end
