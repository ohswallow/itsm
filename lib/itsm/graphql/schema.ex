defmodule Itsm.Graphql.Schema do
  use Absinthe.Schema
  alias Itsm.Graphql.{ContentTypes, Middlewares.Authorize, Resolver}
  import Itsm.Graphql.Macros

  import_types(ContentTypes)

  query do
    @desc "페이징 처리 및 검색 기능이 포함된 일반 포스트 목록 조회\n 필요 권한: 어드민\n검색 가능 컬럼은 상세 참조"
    field :list_posts, :paginated_posts do
      pagination_args(
        [
          :title,
          :content,
          :metadata,
          author: :display_name,
          board: :name
        ],
        [:updated_at, :inserted_at]
      )

      middleware(Authorize, ["admin"])

      resolve(&Resolver.list_posts/3)
    end

    @desc "특정 단건 포스트 상세 조회"
    field :get_post, :post do
      arg(:id, non_null(:string))

      middleware(Authorize, [])

      resolve(&Resolver.get_post!/3)
    end
  end
end
