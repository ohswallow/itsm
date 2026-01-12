defmodule Itsm.Service.Request do
  use Ecto.Schema
  import Ecto.Changeset

  alias Itsm.Service.CommonKCreateVm
  alias Itsm.Service.Category
  alias Itsm.Service.Approval
  alias Itsm.Attachments.Attachment

  @status_values [:request, :check, :plan, :review, :start, :finish, :verify, :closed]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "requests" do
    field :title, :string
    field :description, :string
    field :env, Ecto.Enum, values: [:prod, :stg, :dev, :dr]
    field :due_date, :utc_datetime
    # field :requestor_id, :binary_id

    field :requestor_name, :string
    # field :requestor_id, :string

    # field :assignee_id, :string
    field :assignee_name, :string
    # field :assignee_crew_name, :string

    field :status, Ecto.Enum,
      values: @status_values,
      default: :request

    belongs_to :assignee, Itsm.Accounts.User
    belongs_to :assignee_crew, Itsm.Team.Crew, type: :binary_id
    belongs_to :requestor, Itsm.Accounts.User
    belongs_to :requestor_crew, Itsm.Team.Crew, type: :binary_id
    belongs_to :category, Category, type: :integer
    embeds_many :common_k_create_vms, CommonKCreateVm, on_replace: :delete

    has_many :approvals, Approval
    has_many :comments, Itsm.Comments.Comment
    has_many :attachments, Attachment, on_replace: :delete

    # has_many :referenced_crews, Itsm.Team.Reference, foreign_key: :reference_id, where: [reference_type: "Request"]
    has_many :references, Itsm.Team.Reference,
      foreign_key: :reference_id,
      where: [reference_type: "Request"]

    # has_many :referenced_crews, through: [:references, :crew]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(request, attrs) do
    request
    |> cast(attrs, [
      :title,
      :description,
      :env,
      :due_date,
      :requestor_crew_id
    ])
    |> validate_required([
      :title,
      :description,
      :env,
      :due_date,
      :assignee_id,
      :requestor_crew_id
    ])
    |> cast_embed(:common_k_create_vms,
      with: &CommonKCreateVm.changeset/2,
      drop_param: :common_k_create_vms_drop,
      sort_param: :common_k_create_vms_sort
    )
    |> assoc_constraint(:assignee)
    |> assoc_constraint(:category)
    # attachments 데이터를 같이 받아서 한 번에 저장
    |> cast_assoc(:attachments, with: &Attachment.changeset/2)

    # |> validate_assignee_not_requestor()
  end
end
