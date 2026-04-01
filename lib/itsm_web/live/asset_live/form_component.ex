defmodule ItsmWeb.AssetLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Assets

  @impl true
  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  @impl true
  def update(%{asset: asset} = assigns, socket) do
    {:ok,
     socket
     |> assign_new_options()
     |> assign(assigns)
     |> assign(:conflict, false)
     |> assign_new(:form, fn ->
       to_form(Assets.change_asset(asset))
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage asset records in your database.</:subtitle>
      </.header>

      <div
        :if={@conflict}
        class="p-4 mb-4 bg-red-50 border border-red-200 text-red-800 rounded animate-pulse"
      >
        <div class="flex items-center gap-2 font-bold">
          <span>⚠️ 충돌 발생!</span>
        </div>
        <p class="mt-1 text-sm">{@conflict_msg}</p>
        <p class="mt-2 text-xs opacity-75">현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.</p>
      </div>

      <.simple_form
        for={@form}
        id="asset-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={gettext("Name")} />
        <.input field={@form[:description]} type="text" label={gettext("Description")} />
        <.input
          field={@form[:affiliate]}
          type="select"
          label={gettext("Affiliate")}
          prompt="Choose a value"
          options={@affiliate_options}
        />
        <.input
          field={@form[:category]}
          type="select"
          label={gettext("Category")}
          prompt="Choose a value"
          options={@category_options}
        />
        <.input
          field={@form[:region_type]}
          type="select"
          label={gettext("Region type")}
          prompt="Choose a value"
          options={@region_type_options}
        />
        <.input
          field={@form[:infra_type]}
          type="select"
          label={gettext("Infra type")}
          prompt="Choose a value"
          options={@infra_type_options}
        />
        <.input
          field={@form[:env]}
          type="select"
          label={gettext("Environment")}
          prompt="Choose a value"
          options={@env_options}
        />
        <.input
          field={@form[:location]}
          type="select"
          label={gettext("Location")}
          prompt="Choose a value"
          options={@location_options}
        />
        <.input field={@form[:is_dmz_zone]} type="checkbox" label={gettext("Is dmz zone")} />
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Asset</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset = Assets.change_asset(socket.assigns.asset, asset_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_params)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:affiliate_options, fn -> Itsm.CommonCodes.get_select_options("계열사") end)
    |> assign_new(:category_options, fn -> Itsm.CommonCodes.get_select_options("카테고리") end)
    |> assign_new(:region_type_options, fn -> Itsm.CommonCodes.get_select_options("지역_유형") end)
    |> assign_new(:infra_type_options, fn -> Itsm.CommonCodes.get_select_options("인프라_유형") end)
    |> assign_new(:env_options, fn -> Itsm.CommonCodes.get_select_options("운영_구분") end)
    |> assign_new(:location_options, fn -> Itsm.CommonCodes.get_select_options("장소") end)
  end

  defp save_asset(socket, :new, asset_params) do
    case Assets.create_asset(asset_params) do
      {:ok, _asset} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset(socket, :edit, asset_params) do
    case Assets.update_asset(socket.assigns.asset, asset_params) do
      {:ok, _asset} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
