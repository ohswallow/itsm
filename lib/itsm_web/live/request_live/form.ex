# defmodule ItsmWeb.RequestLive.Form do
#   use ItsmWeb, :live_view

#   alias Itsm.Service
#   alias Itsm.Service.Request

#   @impl true
#   def render(assigns) do
#     ~H"""
#     <.header>
#       {@page_title}
#       <:subtitle>Use this form to manage request records in your database.</:subtitle>
#     </.header>

#     <.simple_form for={@form} id="request-form" phx-change="validate" phx-submit="save">
#       <.input field={@form[:title]} type="text" label="Title" />
#       <.input field={@form[:description]} type="text" label="Description" />
#       <.input
#         field={@form[:env]}
#         type="select"
#         label="Env"
#         prompt="Choose a value"
#         options={Ecto.Enum.values(Itsm.Service.Request, :env)}
#       /> <.input field={@form[:due_date]} type="datetime-local" label="Due date" />
#       <.input
#         field={@form[:status]}
#         type="select"
#         label="Status"
#         prompt="Choose a value"
#         options={Ecto.Enum.values(Itsm.Service.Request, :status)}
#       />
#       <:actions><.button phx-disable-with="Saving...">Save Request</.button></:actions>
#     </.simple_form>

#     <.back navigate={return_path(@return_to, @request)}>Back</.back>
#     """
#   end

#   @impl true
#   def mount(params, _session, socket) do
#     {:ok,
#      socket
#      |> assign(:return_to, return_to(params["return_to"]))
#      |> apply_action(socket.assigns.live_action, params)}
#   end

#   defp return_to("show"), do: "show"
#   defp return_to(_), do: "index"

#   defp apply_action(socket, :edit, %{"id" => id}) do
#     request = Service.get_request!(id)

#     socket
#     |> assign(:page_title, "Edit Request")
#     |> assign(:request, request)
#     |> assign(:form, to_form(Service.change_request(request)))
#   end

#   defp apply_action(socket, :new, _params) do
#     request = %Request{}

#     socket
#     |> assign(:page_title, "New Request")
#     |> assign(:request, request)
#     |> assign(:form, to_form(Service.change_request(request)))
#   end

#   @impl true
#   def handle_event("validate", %{"request" => request_params}, socket) do
#     changeset = Service.change_request(socket.assigns.request, request_params)
#     {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
#   end

#   def handle_event("save", %{"request" => request_params}, socket) do
#     save_request(socket, socket.assigns.live_action, request_params)
#   end

#   defp save_request(socket, :edit, request_params) do
#     case Service.update_request(
#            socket.assigns.current_user,
#            socket.assigns.request,
#            request_params
#          ) do
#       {:ok, request} ->
#         {:noreply,
#          socket
#          |> put_flash(:info, "Request updated successfully")
#          |> push_navigate(to: return_path(socket.assigns.return_to, request))}

#       {:error, %Ecto.Changeset{} = changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp save_request(socket, :new, request_params) do
#     case Service.create_request(request_params) do
#       {:ok, request} ->
#         {:noreply,
#          socket
#          |> put_flash(:info, "Request created successfully")
#          |> push_navigate(to: return_path(socket.assigns.return_to, request))}

#       {:error, %Ecto.Changeset{} = changeset} ->
#         {:noreply, assign(socket, form: to_form(changeset))}
#     end
#   end

#   defp return_path("index", _request), do: ~p"/requests"
#   defp return_path("show", request), do: ~p"/requests/#{request}"
# end
