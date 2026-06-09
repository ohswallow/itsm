defmodule Itsm.Service.Category do
  use Ecto.Schema
  import Ecto.Changeset

  # @primary_key {:id, :binary_id, autogenerate: true}
  # @foreign_key_type :binary_id
  schema "categories" do
    field :active, :boolean, default: true
    field :name, :string
    field :description, :string
    field :group, :string
    # group_code: "계열사"
    field :affiliate, :string
    field :request_name, :string
    # 용도 : SLA 계산용
    field :duration, :integer, default: 60

    # 용도 : 서비스 요청 시 카테고리 구분 (서버, 네트워크, 보안, 미들웨어, 인터페이스 등)
    field :category, :string

    belongs_to :assignee_crew, Itsm.Crews.Crew, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs \\ %{}) do
    category
    |> cast(attrs, [
      :name,
      :description,
      :affiliate,
      :request_name,
      :group,
      :active,
      :duration,
      :assignee_crew_id
    ])
    |> validate_required([
      :name,
      :description,
      :affiliate,
      :request_name,
      :group,
      :active,
      :duration,
      :assignee_crew_id
    ])
    |> unique_constraint(:name)
  end

  def admin_changeset(category, attrs \\ %{}) do
    category
    |> cast(attrs, [
      :name,
      :description,
      :affiliate,
      :request_name,
      :group,
      :active,
      :category,
      :duration,
      :assignee_crew_id
    ])
    |> validate_required([
      :name,
      :description,
      :affiliate,
      :request_name,
      :group,
      :active,
      :duration,
      :assignee_crew_id
    ])
    |> unique_constraint(:name)
  end
end
