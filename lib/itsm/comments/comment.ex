defmodule Itsm.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :comment, :string

    # [핵심] 부모가 누구인지 구분하기 위한 필드
    field :resource_type, :string
    field :resource_id, :binary_id
    # field :request_id, :binary_id

    # 댓글에 달린 첨부파일들 (이 파일의 부모는 Comment가 됨)
    has_many :attachments, Itsm.Attachments.Attachment,
      foreign_key: :resource_id,
      where: [resource_type: "Comment"],
      on_replace: :delete

    # belongs_to :request, Itsm.Service.Request
    belongs_to :user, Itsm.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs \\ %{}) do
    comment
    |> cast(attrs, [:comment, :resource_type, :resource_id])
    |> validate_required([:comment, :resource_type, :resource_id])
    |> validate_length(:comment, min: 1, max: 1000)
    |> assoc_constraint(:user)
  end
end
