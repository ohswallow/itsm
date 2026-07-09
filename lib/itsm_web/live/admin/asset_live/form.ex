defmodule ItsmWeb.Admin.AssetLive.Form do
  use ItsmWeb, :live_view

  alias Itsm.Admin.Assets
  alias Itsm.Assets.Asset
  alias Itsm.Admin.CommonCodes

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:conflict, false)
     |> assign(:conflict_msg, fn -> nil end)
     |> assign_new_options()}
  end

  def handle_params(params, url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params, url)}
  end

  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset = Assets.change_asset(%Asset{}, asset_params)

    current_category = asset_params["category"]
    dynamic_fields = Assets.metadata_fields_for_category(current_category)

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))
     |> assign(dynamic_fields: dynamic_fields)}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.live_action, asset_params)
  end

  def handle_info({:pubsub, {action_user, event, item}}, socket) do
    handle_pubsub(action_user, event, item, socket)
  end

  def handle_info(_event, socket), do: {:noreply, socket}

  defp apply_action(socket, :new, _params, _url) do
    asset = %Asset{}

    socket
    |> assign(:page_title, gettext("New Asset"))
    |> assign(:asset, asset)
    |> assign_new(:form, fn -> to_form(Assets.change_asset(asset)) end)
    |> assign_new(:dynamic_fields, fn -> Assets.metadata_fields_for_category(nil) end)
  end

  defp apply_action(socket, :edit, %{"id" => id}, _url) do
    asset = Assets.get_asset!(id)

    socket
    |> assign(:page_title, gettext("Edit Asset"))
    |> assign(:asset, asset)
    |> assign_new(:form, fn -> to_form(Assets.change_asset(asset)) end)
    |> assign_new(:dynamic_fields, fn -> Assets.metadata_fields_for_category(asset.category) end)
    |> Itsm.PubSub.Helper.subscribe(Assets, id: id, is_admin: true)
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:affiliate_options, fn -> CommonCodes.get_select_options("계열사") end)
    |> assign_new(:category_options, fn -> CommonCodes.get_select_options("카테고리") end)
    |> assign_new(:region_type_options, fn -> CommonCodes.get_select_options("지역_유형") end)
    |> assign_new(:infra_type_options, fn -> CommonCodes.get_select_options("인프라_유형") end)
    |> assign_new(:env_options, fn -> CommonCodes.get_select_options("운영_구분") end)
    |> assign_new(:location_options, fn -> CommonCodes.get_select_options("장소") end)
    |> assign_new(:crew_options, fn -> Itsm.Admin.Crews.get_select_options() end)
  end

  defp save_asset(socket, :edit, asset_params) do
    %{current_scope: %{user: action_user}, asset: asset} = socket.assigns

    case Assets.update_asset(action_user, asset, asset_params) do
      {:ok, _asset} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/assets")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset(socket, :new, asset_params) do
    %{current_scope: %{user: action_user}} = socket.assigns

    case Assets.create_asset(action_user, asset_params) do
      {:ok, _asset} ->
        {:noreply, socket |> push_navigate(to: ~p"/admin/assets")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp handle_pubsub(
         action_user,
         :update_asset,
         %{id: id},
         %{assigns: %{asset: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 수정했습니다.")
     |> put_flash(:error, "데이터가 변경되었습니다. 새로고침 후 수정해주세요.")}
  end

  defp handle_pubsub(
         action_user,
         :delete_asset,
         %{id: id},
         %{assigns: %{asset: %{id: id}}} = socket
       ) do
    {:noreply,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{action_user.display_name}님이 데이터를 삭제했습니다.")
     |> put_flash(:error, "데이터가 삭제되었습니다. 목록으로 돌아갑니다.")
     |> push_navigate(to: ~p"/admin/assets")}
  end
end
