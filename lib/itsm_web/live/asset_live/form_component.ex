defmodule ItsmWeb.AssetLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage asset records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="asset-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input
          field={@form[:affiliate]}
          type="select"
          label="Affiliate"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Assets.Asset, :affiliate)}
        />
        <.input
          field={@form[:category]}
          type="select"
          label="Category"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Assets.Asset, :category)}
        />
        <.input
          field={@form[:region_type]}
          type="select"
          label="Region type"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Assets.Asset, :region_type)}
        />
        <.input
          field={@form[:infra_type]}
          type="select"
          label="Infra type"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Assets.Asset, :infra_type)}
        />
        <.input
          field={@form[:env]}
          type="select"
          label="Env"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Assets.Asset, :env)}
        />
        <.input
          field={@form[:location]}
          type="select"
          label="Location"
          prompt="Choose a value"
          options={Ecto.Enum.values(Itsm.Assets.Asset, :location)}
        />
        <.input field={@form[:is_dmz_zone]} type="checkbox" label="Is dmz zone" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Asset</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{asset: asset} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Assets.change_asset(asset))
     end)}
  end

  @impl true
  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset = Assets.change_asset(socket.assigns.asset, asset_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    save_asset(socket, socket.assigns.action, asset_params)
  end

  defp save_asset(socket, :edit, asset_params) do
    case Assets.update_asset(socket.assigns.asset, asset_params) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_asset(socket, :new, asset_params) do
    case Assets.create_asset(asset_params) do
      {:ok, asset} ->
        notify_parent({:saved, asset})

        {:noreply,
         socket
         |> put_flash(:info, "Asset created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
