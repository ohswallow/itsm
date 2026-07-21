defmodule ItsmWeb.ImageViewerComponent do
  use ItsmWeb, :live_component

  alias ItsmWeb.LiveUtils

  attr :id, :string, required: true
  attr :images, Phoenix.LiveView.LiveStream, required: true
  attr :image_count, :integer, required: true
  attr :show_delete?, :boolean, default: true

  def viewer(assigns) do
    ~H"""
    <.live_component
      module={__MODULE__}
      id={@id}
      images={@images}
      image_count={@image_count}
      show_delete?={@show_delete?}
    />
    """
  end

  def render(assigns) do
    ~H"""
    <div>
      <div :if={@image_count > 0} class="mt-8">
        <h2 class="text-lg font-semibold text-zinc-700 mb-4">첨부파일 ({@image_count})</h2>
        
        <div
          id={"#{@id}_img_container"}
          class="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-6 gap-3"
          phx-update="stream"
        >
          <div
            :for={{dom_id, image} <- @images}
            id={dom_id}
            class="relative group w-full max-w-[200px]"
          >
            <div
              class="card card-compact bg-base-100 border border-base-200 shadow-sm hover:shadow-md transition-all duration-200 cursor-pointer overflow-hidden group/card"
              phx-click="view_image"
              phx-value-id={image.id}
              phx-value-filename={image.filename}
              phx-value-modal-id={"modal-#{@id}"}
              phx-target={@myself}
            >
              <div class="relative aspect-square bg-base-200">
                <img
                  src={~p"/attachments/download/#{image.id}"}
                  alt={image.filename}
                  class="w-full h-full object-cover"
                />
                <div class="absolute inset-0 bg-neutral/40 opacity-0 group-hover/card:opacity-100 transition-opacity duration-200 flex items-center justify-center">
                  <.icon
                    name="hero-magnifying-glass-plus"
                    class="w-8 h-8 text-neutral-content animate-in zoom-in-75 duration-100"
                  />
                </div>
              </div>
              
              <div class="card-body p-3 gap-0.5">
                <h4 class="card-title text-xs font-medium text-base-content truncate block">
                  {image.filename}
                </h4>
                
                <div class="card-actions justify-between items-center mt-1">
                  <span class="text-[10px] text-base-content/60">
                    {LiveUtils.format_file_size(image.byte_size)}
                  </span>
                </div>
              </div>
            </div>
            
            <button
              :if={@show_delete?}
              type="button"
              class="absolute -top-2 -right-2 btn btn-circle btn-xs btn-error shadow-sm scale-0 group-hover:scale-100 transition-all duration-200 z-10"
              phx-click="delete_image"
              phx-value-id={image.id}
              phx-target={@myself}
              data-confirm="정말로 이 첨부파일을 삭제하시겠습니까?"
            >
              <.icon name="hero-x-mark" class="w-3 h-3" />
            </button>
          </div>
        </div>
        
        <.daisy_modal id={"modal-#{@id}"} title={@filename}>
          <div class="text-center">
            <img
              src={~p"/attachments/download/#{@file_id}"}
              alt={@filename}
              class="max-h-[80vh] mx-auto rounded-lg object-contain"
            />
            <div class="mt-4 flex items-center justify-center gap-4">
              <.button
                href={~p"/attachments/download/#{@file_id}"}
                download={@filename}
                class="link link-primary link-hover flex items-center gap-1 text-sm "
              >
                <.icon name="hero-arrow-down-tray" class="w-4 h-4" /> {gettext("DownLoad")}
              </.button>
            </div>
          </div>
        </.daisy_modal>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:file_id, fn -> "" end)
     |> assign_new(:filename, fn -> "" end)}
  end

  def handle_event(
        "view_image",
        %{"id" => id, "filename" => filename, "modal-id" => modal_id},
        socket
      ) do
    {:noreply,
     assign(socket, :file_id, id)
     |> assign(:filename, filename)
     |> push_event("daisy:modal:show", %{id: modal_id})}
  end

  def handle_event("delete_image", %{"id" => image_id}, socket) do
    send(self(), {:delete_image, socket.assigns.id, image_id})
    {:noreply, socket}
  end
end
