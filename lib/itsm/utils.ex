defmodule Itsm.Utils do
  @moduledoc """
  ITSM 개발에 필요한 BIZ모듈에서 사용할 Util메소드 정의 합니다.
  """
  def resource_name(%module{}) do
    module
    |> Module.split()
    |> List.last()
  end

  def maybe_put_change(changeset, _field, nil), do: changeset

  def maybe_put_change(changeset, field, value),
    do: Ecto.Changeset.put_change(changeset, field, value)
end
