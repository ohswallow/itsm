defmodule Itsm.Graphql.Schema do
  use Absinthe.Schema
  alias Itsm.Graphql.{ContentTypes, Middlewares, Resolver}

  import_types(ContentTypes)

  query do
    @desc "모든 게시판 요청, admin 권한 필요"
    field :list_posts, list_of(:post) do
      middleware(Middlewares.Authorize, ["admin"])

      resolve(&Resolver.list_posts/3)
    end
  end
end
