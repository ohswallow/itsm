defmodule ItsmWeb.Admin.PostLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Admin.Posts

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{post: post} = assigns, socket) do
    selected_board =
      if assigns.action == :edit, do: Itsm.Admin.Boards.get_board!(post.board_id), else: %{}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:conflict, false)
     |> assign_new(:form, fn ->
       to_form(Posts.change_post(post))
     end)
     |> assign(:selected_board, selected_board)
     |> assign_new_options()}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage post records in your database.</:subtitle>
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
        id="post-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:board_id]}
          type="select"
          label={gettext("Board")}
          prompt="선택해주세요"
          options={@board_options}
        />
        <.input
          field={@form[:title]}
          type="text"
          label={gettext("Title")}
        />
        <.input field={@form[:content]} type="text" label={gettext("Content")} />
        <div
          :if={assigns[:selected_board] && Map.get(@selected_board, :metadata, %{})["fields"]}
          class="space-y-4"
        >
          <fragment :for={field <- @selected_board.metadata["fields"] || []}>
            <.input
              :if={field && field["type"] !== "date"}
              id={"#{@form[:metadata].name}_#{field["name"]}"}
              name={"#{@form[:metadata].name}[#{field["name"]}]"}
              value={
                case @form[:metadata].value do
                  m when is_map(m) -> Map.get(m, field["name"]) || field["default"]
                  _ -> field["default"]
                end
              }
              type={field["type"]}
              label={field["label"]}
              autocomplete={if field["type"] == "password", do: "new-password", else: "one-time-code"}
              options={Map.get(field, "options", [])}
            />
            <.itsm_calendar
              :if={field && field["type"] === "date"}
              field={
                %Phoenix.HTML.FormField{
                  id: "post_metadata_#{field["name"]}",
                  form: @form[:metadata].form,
                  name: "post[metadata][#{field["name"]}]",
                  errors: [],
                  field: String.to_atom(field["name"]),
                  value: ""
                }
              }
              label={field["label"]}
              show_time
              default_selected_date_time={
                @form[:metadata].value != [""] && @form[:metadata].value[field["name"]]
              }
              rests={%{hour: %{name: ""}, minute: %{name: ""}}}
            />
            <.error
              :for={
                {msg, opts} <-
                  Enum.filter(@form[:metadata].errors || [], fn {_msg, opt} ->
                    opt[:field] == field["name"]
                  end)
              }
              :if={
                val = @form[:metadata].value || %{}
                targetMap = if is_map(val), do: val, else: %{}

                Map.has_key?(targetMap, field["name"]) &&
                  !Map.has_key?(targetMap, "_unused_#{field["name"]}")
              }
            >
              {translate_error({msg, opts})}
            </.error>
          </fragment>
        </div>
        <.itsm_calendar
          :if={@action == :edit}
          field={@form[:inserted_at]}
          label={gettext("Inserted At")}
          show_time
          default_selected_date_time={@form[:inserted_at].value}
        />
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Post</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    selected_board =
      get_effective_board(
        post_params["board_id"],
        Map.get(socket.assigns[:post], :board_id),
        socket.assigns[:selected_board]
      )

    changeset =
      Posts.change_post(
        socket.assigns.post,
        attrs: post_params,
        current_user: socket.assigns.current_user,
        selected_board_metadata: Map.get(selected_board, :metadata, %{}),
        call_back: &Itsm.Utils.maybe_put_change(&1, :inserted_at, post_params["inserted_at"])
      )

    {:noreply,
     socket
     |> assign(:selected_board, selected_board)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    selected_board =
      get_effective_board(
        post_params["board_id"],
        Map.get(socket.assigns[:post], :board_id),
        socket.assigns[:selected_board]
      )

    save_post(
      socket,
      socket.assigns.action,
      post_params,
      socket.assigns.current_user,
      Map.get(selected_board, :metadata, %{})
    )
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:board_options, fn -> Itsm.Admin.Boards.get_select_options() end)
    |> assign_new(:author_options, fn -> Itsm.Admin.Accounts.get_select_options() end)
  end

  defp save_post(socket, :edit, post_params, current_user, selected_board_metadata) do
    case Posts.update_post(
           socket.assigns.post,
           post_params,
           current_user,
           selected_board_metadata
         ) do
      {:ok, _post} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :new, post_params, current_user, selected_board_metadata) do
    case Posts.create_post(post_params, current_user, selected_board_metadata) do
      {:ok, _post} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp get_effective_board(new_id, current_board_id, current_board) do
    empty? = fn val -> is_nil(val) || val == "" end

    cond do
      empty?.(new_id) ->
        %{}

      is_nil(current_board) && !empty?.(current_board_id) ->
        Itsm.Admin.Boards.get_board!(current_board_id)

      !empty?.(new_id) &&
          (is_nil(current_board) || current_board == %{} || new_id != current_board.id) ->
        Itsm.Admin.Boards.get_board!(new_id)

      is_nil(current_board) && !empty?.(current_board_id) ->
        Itsm.Admin.Boards.get_board!(current_board_id)

      true ->
        current_board
    end
  end
end
