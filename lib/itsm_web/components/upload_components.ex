defmodule ItsmWeb.UploadComponents do
  use ItsmWeb, :html
  alias ItsmWeb.LiveUtils

  attr :upload, Phoenix.LiveView.UploadConfig, required: true

  def dropzone(assigns) do
    ~H"""
    <div>
      <.live_file_input class="hidden" upload={@upload} />
      <label
        class="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed rounded-lg cursor-pointer bg-base-100 border-base-300 hover:bg-base-200/50 mt-2 transition-colors"
        for={@upload.ref}
        phx-drop-target={@upload.ref}
      >
        <div class="flex flex-col items-center justify-center pt-5 pb-6 text-center">
          <.icon name="hero-arrow-up-tray" class="w-8 h-8 mb-3 text-base-content/60" />
          <p class="mb-1 text-sm text-base-content/80">
            <span class="font-semibold text-primary">{gettext("Click to upload or drag and drop")}</span>
          </p>
          
          <p class="text-xs text-base-content/60">
            {@upload.max_entries} {gettext("photos max, up to")} {trunc(
              @upload.max_file_size / (1 * 1024 * 1024)
            )} {gettext("MB each")}
          </p>
        </div>
      </label>
      <!-- 글로벌 업로드 에러 -->
      <div
        :for={err <- upload_errors(@upload)}
        class="alert alert-error py-2 px-3 mt-2 text-sm flex gap-2"
      >
        <.icon name="hero-exclamation-circle" class="size-5 shrink-0" />
        <span>{Phoenix.Naming.humanize(err)}</span>
      </div>
      <!-- 업로드된 이미지 프리뷰 목록 -->
      <div
        :if={length(@upload.entries) > 0}
        class="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-4"
      >
        <div
          :for={entry <- @upload.entries}
          class="card card-compact bg-base-100 border border-base-200 shadow-sm relative group p-2"
        >
          <div class="aspect-square bg-base-200 rounded-md overflow-hidden mb-2 relative">
            <.live_img_preview entry={entry} class="w-full h-full object-cover" />
          </div>
          
          <div class="px-1">
            <p class="text-xs font-medium text-base-content truncate">{entry.client_name}</p>
            
            <p class="text-xs text-base-content/60">
              {LiveUtils.format_file_size(entry.client_size)}
            </p>
          </div>
          <!-- 삭제 버튼: 마우스 호버(group-hover) 효과 추가로 UI 디테일 업 -->
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            class="btn btn-circle btn-xs btn-error absolute -top-2 -right-2 shadow-sm min-h-0 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity"
          >
            <.icon name="hero-x-mark" class="w-3 h-3" />
          </button>
          <!-- 개별 파일 업로드 에러 -->
          <div
            :for={err <- upload_errors(@upload)}
            class="alert alert-error py-1 px-2 mt-1 text-xs flex gap-1"
          >
            <.icon name="hero-exclamation-circle" class="size-4 shrink-0" />
            <span>{Phoenix.Naming.humanize(err)}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
