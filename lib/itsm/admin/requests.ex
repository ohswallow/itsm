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
        Itsm.Utils.broadcast(:request, {:update_request, request})
        Itsm.Utils.broadcasts(:requests, {:update_request, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end

  def delete_request(%Request{} = request) do
    Repo.delete(request)
    |> case do
      {:ok, request} ->
        Itsm.Utils.broadcast(:request, {:update_request, request})
        Itsm.Utils.broadcasts(:requests, {:update_request, request})
        {:ok, request}

      {:error, _} = error ->
        error
    end
  end
end
