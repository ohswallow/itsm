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
    field :duration, :integer, default: 60
    # field :assignee_crew, :string

    belongs_to :assignee_crew, Itsm.Team.Crew, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
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
end
