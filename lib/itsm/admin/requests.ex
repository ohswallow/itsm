defmodule Itsm.Admin.Requests do
  import Ecto.Query, warn: false
  alias Itsm.Repo
  alias Itsm.Service.Request

  defdelegate list_requests, to: Itsm.Requests

  defdelegate get_request!(id), to: Itsm.Requests

  defdelegate change_request(request, attrs \\ %{}), to: Itsm.Requests

  defdelegate create_request(user, attrs \\ %{}), to: Itsm.Requests

  def update_request(%Request{} = request, attrs) do
    request
    |> Request.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, request} ->
        request = Repo.preload(request, :category)
        Itsm.Requests.broadcast_request(request.id, {:request_updated, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def delete_request(%Request{} = request) do
    Repo.delete(request)
  end
end
