defmodule ItsmWeb.Admin.AssetLive.AssetShadowLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.AssetsShadow
  alias Itsm.Assets.AssetShadow
  alias Itsm.Admin.CommonCodes

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{asset_shadow: asset_shadow} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:conflict, fn -> false end)
     |> assign_new(:conflict_msg, fn -> nil end)
     |> assign_new(:form, fn ->
       to_form(AssetsShadow.change_asset_shadow(asset_shadow))
     end)
     |> assign_new(:dynamic_fields, fn ->
       AssetsShadow.metadata_fields_for_category(asset_shadow.category)
     end)
     |> assign_new_options()}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage asset records in your database.</:subtitle>
      </.header>

      <.card
        visible={@conflict}
        state={:error}
        title="⚠️ 충돌 발생!"
      >
        <p>{@conflict_msg}</p>
        <p>현재 편집 내용을 저장할 수 없습니다. 창을 닫고 다시 시도해 주세요.</p>
      </.card>

      <.form
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
          label={gettext("Region Type")}
          prompt="Choose a value"
          options={@region_type_options}
        />
        <.input
          field={@form[:infra_type]}
          type="select"
          label={gettext("Infra Type")}
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
        /> <.input field={@form[:is_dmz_zone]} type="checkbox" label={gettext("Is Dmz Zone")} />
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <.input
          field={@form[:service_crew_id]}
          type="select"
          label={gettext("service_crew")}
          prompt="Choose a value"
          options={@crew_options}
        />
        <.input
          field={@form[:system_crew_id]}
          type="select"
          label={gettext("system_crew")}
          prompt="Choose a value"
          options={@crew_options}
        />

        <div class="grid grid-cols-2 gap-4">
          <.input
            :for={{field_name, type} <- @dynamic_fields}
            field={
              ItsmWeb.LiveUtils.get_sub_field(
                field_name,
                @form[:metadata],
                @form.params["metadata"]
              )
            }
            type={if type in [:integer, :float], do: "number", else: "text"}
            label={field_name |> Atom.to_string() |> String.capitalize()}
          />
        </div>

        <.input
          field={@form[:asset_id]}
          type="select"
          label={gettext("asset")}
          prompt="Choose a value"
          options={@asset_options}
        />

        <.button :if={!@conflict} phx-disable-with="Saving...">Save AssetShadow</.button>
      </.form>
    </div>
    """
  end

  def handle_event("validate", %{"asset_shadow" => asset_shadow_params}, socket) do
    changeset = AssetsShadow.change_asset_shadow(%AssetShadow{}, asset_shadow_params)

    current_category = asset_shadow_params["category"]
    dynamic_fields = AssetsShadow.metadata_fields_for_category(current_category)

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))
     |> assign(dynamic_fields: dynamic_fields)}
  end

  def handle_event("save", %{"asset_shadow" => asset_shadow_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_shadow_params)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:affiliate_options, fn -> CommonCodes.get_select_options("계열사") end)
    |> assign_new(:category_options, fn -> CommonCodes.get_select_options("카테고리") end)
    |> assign_new(:region_type_options, fn -> CommonCodes.get_select_options("지역_유형") end)
    |> assign_new(:infra_type_options, fn -> CommonCodes.get_select_options("인프라_유형") end)
    |> assign_new(:env_options, fn -> CommonCodes.get_select_options("운영_구분") end)
    |> assign_new(:location_options, fn -> CommonCodes.get_select_options("장소") end)
    |> assign_new(:crew_options, fn ->
      Itsm.Crews.list_crews() |> Enum.map(fn crew -> {crew.name, crew.id} end)
    end)
    |> assign_new(:asset_options, fn ->
      Itsm.Assets.list_assets() |> Enum.map(fn asset -> {asset.name, asset.id} end)
    end)
  end

  defp save_asset(socket, :edit, asset_shadow_params) do
    %{current_scope: %{user: action_user}, asset_shadow: asset_shadow} = socket.assigns

    case AssetsShadow.update_asset_shadow(action_user, asset_shadow, asset_shadow_params) do
      {:ok, _asset_shadow} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset(socket, :new, asset_shadow_params) do
    IO.inspect(socket.assigns)
    %{current_scope: %{user: action_user}} = socket.assigns

    case AssetsShadow.create_asset_shadow(action_user, asset_shadow_params) do
      {:ok, _asset_shadow} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
