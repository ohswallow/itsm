defmodule Itsm.Service.Request do
  use Ecto.Schema
  import Ecto.Changeset

  alias Itsm.Service.CommonKCreateVm
  alias Itsm.Service.Category
  alias Itsm.Service.Approval
  alias Itsm.Attachments.Attachment
  alias Itsm.Service.BankKResizeVm

  @status_values [
    :request,
    :validation,
    :assignment,
    :check,
    :start,
    :finish,
    :confirmation,
    :closed,
    :rejected
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "requests" do
    field :title, :string
    field :description, :string
    # group_code: "운영_구분"
    field :env, :string
    field :due_date, :utc_datetime
    field :requestor_name, :string
    field :status, Ecto.Enum, values: @status_values

    belongs_to :assignee_crew, Itsm.Crews.Crew, type: :binary_id
    belongs_to :requestor, Itsm.Accounts.User
    belongs_to :requestor_crew, Itsm.Crews.Crew, type: :binary_id
    belongs_to :category, Category, type: :integer
    embeds_many :common_k_create_vms, CommonKCreateVm, on_replace: :delete
    embeds_many :bank_k_resize_vms, BankKResizeVm, on_replace: :delete

    has_many :approvals, Approval

    has_many :comments, Itsm.Comments.Comment,
      foreign_key: :resource_id,
      where: [resource_type: "Request"]

    has_many :attachments, Itsm.Attachments.Attachment,
      foreign_key: :resource_id,
      where: [resource_type: "Request"],
      on_replace: :delete

    has_many :crew_references, Itsm.Crews.CrewReference,
      foreign_key: :resource_id,
      where: [resource_type: "Request"]

    field :referenced_crews, {:array, :binary_id}, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(request, attrs \\ %{}) do
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
      :requestor_crew_id
    ])
    |> assoc_changeset(attrs)
  end

  @doc false
  defp assoc_changeset(request, _attrs) do
    request
    |> cast_embed(:common_k_create_vms,
      with: &CommonKCreateVm.changeset/2,
      drop_param: :common_k_create_vms_drop,
      sort_param: :common_k_create_vms_sort
    )
    |> cast_embed(:bank_k_resize_vms,
      with: &BankKResizeVm.changeset/2,
      drop_param: :bank_k_resize_vms_drop,
      sort_param: :bank_k_resize_vms_sort
    )
    # |> assoc_constraint(:assignee)
    |> assoc_constraint(:category)
    |> cast_assoc(:attachments, with: &Attachment.changeset/2)
  end

  def delete_changeset(%Ecto.Changeset{} = request) do
    request
    |> foreign_key_constraint(:id,
      name: :approvals_request_id_fkey,
      message: "결재를 먼저 지워주세요"
    )

    # |> foreign_key_constraint(:id,
    #   name: :comments_request_id_fkey,
    #   message: "댓글을 먼저 지워주세요"
    # )
    # |> foreign_key_constraint(:id,
    #   name: :attachments_request_id_fkey,
    #   message: "첨부파일을 먼저 지워주세요"
    # )
  end

  def delete_changeset(%__MODULE__{} = request) do
    request
    |> change()
    |> delete_changeset()
  end

  def admin_changeset(request, attrs \\ %{}) do
    request
    |> cast(attrs, [
      :title,
      :description,
      :env,
      :due_date,
      :category_id,
      :requestor_crew_id
    ])
    |> validate_required([
      :title,
      :description,
      :env,
      :due_date,
      :requestor_crew_id
    ])
    |> assoc_changeset(attrs)
  end
end
