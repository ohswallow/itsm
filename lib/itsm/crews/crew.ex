defmodule Itsm.Crews.Crew do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "crews" do
    field :name, :string
    field :description, :string
    # field :organization, :string
    # field :department, :string

    belongs_to :leader, Itsm.Accounts.User, foreign_key: :leader_id

    many_to_many :users, Itsm.Accounts.User, join_through: Itsm.Crews.CrewsUsers

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(crew, attrs) do
    crew
    |> cast(attrs, [:name, :description])
    |> normalize_name()
    |> validate_required([:name, :description])
    |> unsafe_validate_unique(:name, Itsm.Repo)
    |> unique_constraint(:name)
    |> validate_format(:name, ~r/^[A-Za-z]{5}$/, message: "must be exactly 5 alphabetic letters")
    |> validate_length(:description, min: 5, max: 30)
  end

  def users_changeset(crew, users) do
    crew
    |> change()
    |> put_assoc(:users, users)
  end

  def leader_changeset(crew, %{id: leader_id}) do
    crew
    |> cast(%{leader_id: leader_id}, [:leader_id])
    |> validate_required([:leader_id])
  end

  # Crew 이름을 대문자로 변환
  defp normalize_name(changeset) do
    # get_change는 cast가 끝난 후 "진짜 변경될 값"만 가져옴
    case get_change(changeset, :name) do
      # 이름 변경 없으면 패스
      nil -> changeset
      # 있으면 대문자로 덮어쓰기
      name -> put_change(changeset, :name, String.upcase(name))
    end
  end
end
