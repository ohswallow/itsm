defmodule ItsmWeb.Router do
  use ItsmWeb, :router

  import ItsmWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ItsmWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug ItsmWeb.Plugs.SetLocale
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
  end

  pipeline :scim_api do
    plug :accepts, ["json", "scim+json"]
    plug ExScimPhoenix.Plugs.ScimContentType
    plug ExScimPhoenix.Plugs.ScimAuth
  end

  scope "/", ItsmWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", ItsmWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:itsm, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ItsmWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ItsmWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ItsmWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/", ItsmWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_user,
      on_mount: [
        {ItsmWeb.PathProvider, :set_current_path_on_assigns},
        {ItsmWeb.UserAuth, :log_menu_access},
        {ItsmWeb.UserAuth, :require_authenticated},
        {ItsmWeb.UserAuth, :authenticated_permissions_user}
      ] do
      live "/main", MainLive.Index, :index
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # 내 크루 관리
      live "/crews", CrewLive.Index, :index
      live "/crews/all", CrewLive.AllIndex, :index
      live "/crews/new", CrewLive.Form, :new
      live "/crews/:id/edit", CrewLive.Form, :edit
      live "/crews/:id", CrewLive.Show, :show

      # 카테고리(SR 유형) 목록
      live "/categories", CategoryLive.Index

      live "/approvals", ApprovalLive.Index, :index
      # live "/approvals/:request_id/new-comment", ApprovalLive.Index, :new_comment
      live "/approvals/:request_id/approve", ApprovalLive.Index, :approve
      live "/approvals/:request_id/reject", ApprovalLive.Index, :reject
      live "/approvals/:request_id/feedback", ApprovalLive.Index, :feedback

      # Request 목록
      live "/requests", RequestLive.Index, :index
      live "/requests/:id", RequestLive.Index, :show
      live "/requests/:id/edit", RequestLive.Index, :edit

      # VM 생성
      live "/categories/:id/common-k-create-vm/new", CommonKCreateVmLive.Form, :new
      live "/common-k-create-vm/:id", CommonKCreateVmLive.Show, :show
      live "/common-k-create-vm/:id/edit", CommonKCreateVmLive.Form, :edit
      live "/common-k-create-vm/:id/copy", CommonKCreateVmLive.Form, :copy

      # 대결
      live "/delegations", DelegationLive.Index, :index
      live "/delegations/new", DelegationLive.Index, :new
      live "/delegations/:id/edit", DelegationLive.Index, :edit

      live "/delegations/:id", DelegationLive.Show, :show
      live "/delegations/:id/show/edit", DelegationLive.Show, :edit

      # 평가
      live "/evaluations", EvaluationLive.Index, :index
      live "/evaluations/new", EvaluationLive.Index, :new
      live "/evaluations/:id/edit", EvaluationLive.Index, :edit

      live "/evaluations/:id", EvaluationLive.Show, :show
      live "/evaluations/:id/show/edit", EvaluationLive.Show, :edit

      # 자산 관리
      live "/assets", AssetLive.Index, :index
      live "/assets/new", AssetLive.Form, :new
      live "/assets/:id/edit", AssetLive.Form, :edit
      live "/assets/:id", AssetLive.Show, :show

      live "/boards", BoardLive.Index, :index
      live "/boards/:id", BoardLive.Show, :show

      live "/posts", PostLive.Index, :index
      live "/posts/new", PostLive.Form, :new
      live "/posts/:id/edit", PostLive.Form, :edit
      live "/posts/:id", PostLive.Show, :show
    end

    get "/attachments/download/:id", AttachmentController, :download
    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/admin", ItsmWeb do
    pipe_through [
      :browser,
      :require_authenticated_user,
      :require_role_admin_user
    ]

    live_session :require_admin_user,
      on_mount: [
        {ItsmWeb.PathProvider, :set_current_path_on_assigns},
        {ItsmWeb.UserAuth, :log_menu_access},
        {ItsmWeb.UserAuth, :ensure_is_admin_authenticated},
        {ItsmWeb.UserAuth, :authenticated_permissions_user}
      ] do
      live "/", Admin.CategoryLive.Index, :index

      live "/users", Admin.UserLive.Index, :index
      live "/users/new", Admin.UserLive.Form, :new
      live "/users/:id/edit", Admin.UserLive.Form, :edit
      live "/users/:id", Admin.UserLive.Show, :show

      live "/requests", Admin.RequestLive.Index, :index
      live "/requests/new", Admin.RequestLive.Form, :new
      live "/requests/:id/edit", Admin.RequestLive.Form, :edit
      live "/requests/:id", Admin.RequestLive.Show, :show

      live "/categories", Admin.CategoryLive.Index, :index
      live "/categories/new", Admin.CategoryLive.Form, :new
      live "/categories/:id/edit", Admin.CategoryLive.Form, :edit
      live "/categories/:id", Admin.CategoryLive.Show, :show

      live "/approvals", Admin.ApprovalLive.Index, :index
      live "/approvals/:id/edit", Admin.ApprovalLive.Form, :edit
      live "/approvals/:id", Admin.ApprovalLive.Show, :show

      live "/evaluations", Admin.EvaluationLive.Index, :index
      live "/evaluations/:id/edit", Admin.EvaluationLive.Form, :edit
      live "/evaluations/:id", Admin.EvaluationLive.Show, :show

      live "/crews", Admin.CrewLive.Index, :index
      live "/crews/new", Admin.CrewLive.Form, :new
      live "/crews/:id/edit", Admin.CrewLive.Form, :edit
      live "/crews/:id", Admin.CrewLive.Show, :show

      live "/comments", Admin.CommentLive.Index, :index
      live "/comments/new", Admin.CommentLive.Form, :new
      live "/comments/:id/edit", Admin.CommentLive.Form, :edit
      live "/comments/:id", Admin.CommentLive.Show, :show

      live "/common-codes", Admin.CommonCodeLive.Index, :index
      live "/common-codes/new", Admin.CommonCodeLive.Form, :new
      live "/common-codes/:id/edit", Admin.CommonCodeLive.Form, :edit
      live "/common-codes/:id", Admin.CommonCodeLive.Show, :show

      live "/assets", Admin.AssetLive.Index, :index
      live "/assets/new", Admin.AssetLive.Form, :new
      live "/assets/:id/edit", Admin.AssetLive.Form, :edit
      live "/assets/:id", Admin.AssetLive.Show, :show

      live "/boards", Admin.BoardLive.Index, :index
      live "/boards/new", Admin.BoardLive.Form, :new
      live "/boards/:id/edit", Admin.BoardLive.Form, :edit
      live "/boards/:id", Admin.BoardLive.Show, :show

      live "/posts", Admin.PostLive.Index, :index
      live "/posts/new", Admin.PostLive.Form, :new
      live "/posts/:id/edit", Admin.PostLive.Form, :edit
      live "/posts/:id", Admin.PostLive.Show, :show

      live "/attachments", Admin.AttachmentLive.Index, :index
      live "/attachments/new", Admin.AttachmentLive.Form, :new
      live "/attachments/:id/edit", Admin.AttachmentLive.Form, :edit
      live "/attachments/:id", Admin.AttachmentLive.Show, :show

      live "/roles", Admin.RoleLive.Index, :index
      live "/roles/new", Admin.RoleLive.Form, :new
      live "/roles/:id/edit", Admin.RoleLive.Form, :edit
      live "/roles/:id", Admin.RoleLive.Show, :show

      live "/permissions", Admin.PermissionLive.Index, :index
      live "/permissions/new", Admin.PermissionLive.Form, :new
      live "/permissions/:id/edit", Admin.PermissionLive.Form, :edit
      live "/permissions/:id", Admin.PermissionLive.Show, :show
    end

    get "/login_force/:employee_number", Admin.LoginForceController, :force
  end

  scope "/api" do
    pipe_through [:browser, :require_authenticated_user]

    get "/graphiql", ItsmWeb.GraphiqlController, :index
  end

  scope "/api" do
    pipe_through [:api, ItsmWeb.Plugs.ApiAuth]

    forward "/graphql", Absinthe.Plug, schema: Itsm.Graphql.Schema
  end

  scope "/scim/v2" do
    pipe_through :scim_api
    use ExScimPhoenix.Router
  end

  scope "/sso" do
    pipe_through [:api]
    forward "/", ExSaml.Router
  end
end
