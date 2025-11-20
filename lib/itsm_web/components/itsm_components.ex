defmodule ItsmWeb.ItsmComponents do
  use Phoenix.Component

  @doc """
  Renders a time element that displays a localized time using a LiveView hook.
  yyyy.mm.dd hh:mm
  """
  attr :at, :any, required: true, doc: "UTC DateTime struct or ISO string"
  attr :id, :string, required: true

  def local_time(assigns) do
    ~H"""
    <time
      id={@id}
      phx-hook="LocalTime"
      datetime={@at}
      class="invisible"
    >
      {@at}
    </time>
    """
  end
end
