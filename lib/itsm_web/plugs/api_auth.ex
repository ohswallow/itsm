defmodule ItsmWeb.Plugs.ApiAuth do
  def init(opts), do: opts

  def call(conn, _opts) do
    context = %{current_user: conn.assigns[:current_user]}

    Absinthe.Plug.put_options(conn, context: context)
  end
end
