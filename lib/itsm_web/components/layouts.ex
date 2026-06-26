defmodule ItsmWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ItsmWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  attr :current_path, :string, required: true, doc: "현재 페이지의 URL 경로 (예: /boards/123)"
  attr :current_params, :map, required: true, doc: "현재 페이지의 params map (예: %{menu_id: 456})"
  attr :page_title, :string, required: true, doc: "현재 선택된 페이지 제목"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  slot :inner_block, required: true

  def default(assigns) do
    _default(assigns)
  end

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          
          <li>
            <.theme_toggle />
          </li>
          
          <li>
            <a href="https://phoenix.hexdocs.pm/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>
     <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
      
      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  사이트바 메뉴 링크 컴포넌트
  current_path와 navigate를 비교하여 활성화 상태를 결정합니다.
  menu_id가 제공된 경우 URL 쿼리에서 menu_id를 추출하여 비교합니다.
  """
  attr :navigate, :string, required: true, doc: "링크로 이동할 URL 경로 (예: /boards/123)"
  attr :icon_name, :string, required: true, doc: "Heroicons name, e.g. 'hero-home'"
  attr :current_path, :string, required: true, doc: "현재 페이지의 URL 경로 (예: /boards/123)"
  attr :current_params, :any, required: true, doc: "현재 페이지의 params map (예: %{menu_id: 456}"
  attr :menu_id, :string, default: "", doc: "선택적으로 URL 쿼리에서 menu_id를 추출하여 메뉴 활성화 여부 결정"
  attr :data_tip, :string, default: "", doc: "메뉴가 아이콘만 표출될때 마우스오버시 data-tip형식으로 메뉴표출"
  slot :inner_block, required: true

  def menu(assigns) do
    ~H"""
    <li>
      <.button
        navigate={@navigate}
        class={[
          selected_menu?(@current_path, @current_params, @navigate, @menu_id) &&
            "!bg-neutral !text-neutral-content",
          "is-drawer-open:tooltip is-drawer-open:tooltip-right"
        ]}
        data-tip={@data_tip}
      >
        <.icon name={@icon_name} />
        <span class="is-drawer-open:hidden">{render_slot(@inner_block)}</span>
      </.button>
    </li>
    """
  end

  defp selected_menu?(_current_path, %{menu_id: menu_id}, _navigate, menu_id), do: true

  defp selected_menu?(current_path, _current_params, navigate, _menu_id) do
    String.starts_with?(current_path, navigate)
  end
end
