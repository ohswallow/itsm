defmodule ItsmWeb.RouterUtil do
  def admin_menu_items do
    ItsmWeb.Router.__routes__()
    |> Enum.filter(fn route ->
      String.starts_with?(route.path, "/admin") && !String.equivalent?(route.path, "/admin") &&
        route.plug == Phoenix.LiveView.Plug &&
        route.plug_opts == :index
    end)
    |> Enum.map(fn route ->
      name =
        route.metadata[:label] ||
          route.path
          |> String.split("/")
          |> List.last()
          |> String.replace("-", " ")
          |> String.replace("_", " ")
          |> String.capitalize()

      %{name: name, path: route.path}
    end)
    |> Enum.uniq_by(& &1.path)
  end
end
