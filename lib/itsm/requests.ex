defmodule Itsm.Requests do
  alias Itsm.Service.Request
  alias Itsm.Accounts.User
  alias Itsm.Service.Category

  def change_request(%User{} = user, %Category{} = category, %User{} = assignee, attrs \\ %{}) do
    %Request{
      requestor: user,
      requestor_name: user.display_name,
      assignee: assignee,
      assignee_name: assignee.display_name,
      category: category
    }
    |> Request.changeset(attrs)
  end
end
