defmodule ItsmWeb.PostLive.FormComponent do
  use ItsmWeb, :live_component

  alias Itsm.Posts

  def update(%{conflict: {event, user}} = _assigns, socket) do
    msg = if String.contains?(to_string(event), "delete"), do: "삭제", else: "수정"

    {:ok,
     socket
     |> assign(:conflict, true)
     |> assign(:conflict_msg, "#{user.display_name}님이 데이터를 #{msg}했습니다.")}
  end

  def update(%{post: post, board_id: board_id} = assigns, socket) do
    selected_board =
      if assigns.action == :edit,
        do: Itsm.Boards.get_board!(post.board_id),
        else: board_id && Itsm.Boards.get_board!(board_id)

    post = Map.put(post || %{}, :board_id, selected_board.id)

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
        {assigns[:board_name] || "Not Found"}
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
          field={@form[:title]}
          type="text"
          label={gettext("Title")}
        />
        <.input field={@form[:content]} type="textarea" label={gettext("Content")} />
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
                  form: @form[:metadata],
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
                  Enum.filter(Map.get(@form[:metadata], :errors) || [], fn {_msg, opt} ->
                    opt[:field] == field["name"]
                  end)
              }
              :if={
                val = Map.get(@form[:metadata], :value) || %{}
                targetMap = if is_map(val), do: val, else: %{}

                Map.has_key?(targetMap, field["name"]) &&
                  !Map.has_key?(targetMap, "_unused_#{field["name"]}")
              }
            >
              {translate_error({msg, opts})}
            </.error>
          </fragment>
        </div>
        <:actions>
          <.button :if={!@conflict} phx-disable-with="Saving...">Save Post</.button>
        </:actions>

        <.error :for={{msg, opts} <- Map.get(@form[:board_id], :errors) || []}>
          Board {translate_error({msg, opts})}
        </.error>
      </.simple_form>
    </div>
    """
  end

  def handle_event("validate", %{"post" => post_params}, socket) do
    %{current_user: action_user, post: post} = socket.assigns
    selected_board = Itsm.Boards.get_board!(socket.assigns[:board_id] || post_params["board_id"])
    post = Map.put(post, :board_id, selected_board.id)

    changeset =
      Posts.change_post(
        post,
        action_user: action_user,
        attrs: post_params,
        selected_board_metadata: Map.get(selected_board, :metadata, %{})
      )

    {:noreply,
     socket
     |> assign(:selected_board, selected_board)
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    selected_board = Itsm.Boards.get_board!(socket.assigns.board_id)
    post_params = Map.put(post_params, "board_id", selected_board.id)

    save_post(
      socket,
      socket.assigns.action,
      post_params,
      Map.get(selected_board, :metadata, %{})
    )
  end

  defp assign_new_options(socket) do
    socket
    |> assign_new(:board_options, fn -> Itsm.Boards.get_select_options() end)
    |> assign_new(:author_options, fn -> Itsm.Accounts.get_select_options() end)
  end

  defp save_post(socket, :edit, post_params, selected_board_metadata) do
    %{current_user: action_user, post: post} = socket.assigns

    case Posts.update_post(action_user, post, post_params, selected_board_metadata) do
      {:ok, _post} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :new, post_params, selected_board_metadata) do
    %{current_user: action_user} = socket.assigns

    case Posts.create_post(action_user, post_params, selected_board_metadata) do
      {:ok, _post} ->
        {:noreply, socket |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
