defmodule Itsm.Service do
  @moduledoc """
  The Service context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Itsm.Repo
  alias Itsm.Service.Category
  alias Itsm.Accounts.User
  alias Itsm.Attachments.Attachment
  alias Itsm.Requests
  alias Itsm.Approvals

  # ==================================================
  # SR 생성
  # ==================================================

  def create_request(
        %User{} = user,
        %Category{} = category,
        request_params \\ %{},
        attachments \\ []
      ) do
    Multi.new()
    |> Multi.insert(
      :request,
      Requests.change_request(
        user,
        category,
        request_params
      )
    )
    # 3. 첨부파일 처리 (패턴 매칭 사용)
    |> maybe_insert_attachments(attachments)
    # 4. 결재선 생성
    |> Multi.run(:approval, fn repo, %{request: request} ->
      Itsm.Approvals.create_approval(repo, request, user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{request: request}} ->
        request = Repo.preload(request, [:category, :attachments])
        Approvals.broadcast_approvals_list({:request_created, request})
        {:ok, request}

      {:error, _step, changeset, _changes} ->
        {:error, changeset}
    end
  end

  # ==================================================
  # Attachments (Private)
  # ==================================================

  # ✅ 첨부파일 처리: 빈 리스트일 경우 (Multi 그대로 반환)
  defp maybe_insert_attachments(multi, []), do: multi

  defp maybe_insert_attachments(multi, attachments) do
    Multi.run(multi, :attachments, fn repo, %{request: request} ->
      results =
        Enum.map(attachments, fn attachment_params ->
          %Attachment{}
          |> Attachment.changeset(
            Map.merge(attachment_params, %{
              "resource_type" => "Request",
              "resource_id" => request.id
            })
          )
          |> repo.insert()
        end)

      # 모든 첨부파일이 성공적으로 저장되었는지 확인
      if Enum.all?(results, &match?({:ok, _}, &1)) do
        {:ok, results}
      else
        errors = Enum.reject(results, &match?({:ok, _}, &1))
        {:error, :attachment_save_failed, errors}
      end
    end)
  end
end
