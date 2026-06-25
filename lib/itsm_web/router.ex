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
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_user
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
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {ItsmWeb.UserAuth, :require_authenticated},
        {ItsmWeb.UserAuth, :set_locale},
        {ItsmWeb.PathProvider, :set_current_path_on_assigns},
        {ItsmWeb.UserAuth, :log_menu_access}
      ] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # 내 크루 관리
      live "/crews", CrewLive.Index, :index
      live "/crews/all", CrewLive.AllIndex, :index
      live "/crews/new", CrewLive.Index, :new
      live "/crews/:id/edit", CrewLive.Index, :edit
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
      live "/assets/new", AssetLive.Index, :new
      live "/assets/:id/edit", AssetLive.Index, :edit

      live "/assets/:id", AssetLive.Show, :show
      live "/assets/:id/show/edit", AssetLive.Show, :edit

      get "/attachments/download/:id", AttachmentController, :download

      live "/boards", BoardLive.Index, :index

      live "/boards/:id", BoardLive.Show, :show

      live "/posts", PostLive.Index, :index
      live "/posts/new", PostLive.Index, :new
      live "/posts/:id/edit", PostLive.Index, :edit

      live "/posts/:id", PostLive.Show, :show
      live "/posts/:id/show/edit", PostLive.Show, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", ItsmWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ItsmWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/admin", ItsmWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_admin_user,
      on_mount: [
        {ItsmWeb.UserAuth, :ensure_is_admin_authenticated},
        {ItsmWeb.UserAuth, :set_locale},
        {ItsmWeb.PathProvider, :set_current_path_on_assigns},
        {ItsmWeb.UserAuth, :log_menu_access}
      ],
      layout: {ItsmWeb.Layouts, :admin} do
      live "/", Admin.CategoryLive.Index, :index

      live "/users", Admin.UserLive.Index, :index
      live "/users/new", Admin.UserLive.Index, :new
      live "/users/:id/edit", Admin.UserLive.Index, :edit

      live "/users/:id", Admin.UserLive.Show, :show
      live "/users/:id/show/edit", Admin.UserLive.Show, :edit

      live "/requests", Admin.RequestLive.Index, :index
      live "/requests/new", Admin.RequestLive.Index, :new
      live "/requests/:id/edit", Admin.RequestLive.Index, :edit

      live "/requests/:id", Admin.RequestLive.Show, :show
      live "/requests/:id/show/edit", Admin.RequestLive.Show, :edit

      live "/categories", Admin.CategoryLive.Index, :index
      live "/categories/new", Admin.CategoryLive.Index, :new
      live "/categories/:id/edit", Admin.CategoryLive.Index, :edit

      live "/categories/:id", Admin.CategoryLive.Show, :show
      live "/categories/:id/show/edit", Admin.CategoryLive.Show, :edit

      live "/approvals", Admin.ApprovalLive.Index, :index
      live "/approvals/:id/edit", Admin.ApprovalLive.Index, :edit

      live "/approvals/:id", Admin.ApprovalLive.Show, :show
      live "/approvals/:id/show/edit", Admin.ApprovalLive.Show, :edit

      live "/crews", Admin.CrewLive.Index, :index
      live "/crews/new", Admin.CrewLive.Index, :new
      live "/crews/:id/edit", Admin.CrewLive.Index, :edit

      live "/crews/:id", Admin.CrewLive.Show, :show
      live "/crews/:id/show/edit", Admin.CrewLive.Show, :edit

      live "/comments", Admin.CommentLive.Index, :index
      live "/comments/:id/edit", Admin.CommentLive.Index, :edit

      live "/comments/:id", Admin.CommentLive.Show, :show
      live "/comments/:id/show/edit", Admin.CommentLive.Show, :edit

      live "/common-codes", Admin.CommonCodeLive.Index, :index
      live "/common-codes/new", Admin.CommonCodeLive.Index, :new
      live "/common-codes/:id/edit", Admin.CommonCodeLive.Index, :edit

      live "/common-codes/:id", Admin.CommonCodeLive.Show, :show
      live "/common-codes/:id/show/edit", Admin.CommonCodeLive.Show, :edit

      live "/assets", Admin.AssetLive.Index, :index
      live "/assets/new", Admin.AssetLive.Index, :new
      live "/assets/:id/edit", Admin.AssetLive.Index, :edit

      live "/assets/:id", Admin.AssetLive.Show, :show
      live "/assets/:id/show/edit", Admin.AssetLive.Show, :edit

      live "/boards", Admin.BoardLive.Index, :index
      live "/boards/new", Admin.BoardLive.Index, :new
      live "/boards/:id/edit", Admin.BoardLive.Index, :edit

      live "/boards/:id", Admin.BoardLive.Show, :show
      live "/boards/:id/show/edit", Admin.BoardLive.Show, :edit

      live "/posts", Admin.PostLive.Index, :index
      live "/posts/new", Admin.PostLive.Index, :new
      live "/posts/:id/edit", Admin.PostLive.Index, :edit

      live "/posts/:id", Admin.PostLive.Show, :show
      live "/posts/:id/show/edit", Admin.PostLive.Show, :edit

      live "/attachments", Admin.AttachmentLive.Index, :index
      live "/attachments/new", Admin.AttachmentLive.Index, :new
      live "/attachments/:id/edit", Admin.AttachmentLive.Index, :edit

      live "/attachments/:id", Admin.AttachmentLive.Show, :show
      live "/attachments/:id/show/edit", Admin.AttachmentLive.Show, :edit

      live "/assets-shadow", Admin.AssetLive.AssetShadowLive.Index, :index
      live "/assets-shadow/new", Admin.AssetLive.AssetShadowLive.Index, :new
      live "/assets-shadow/:id/edit", Admin.AssetLive.AssetShadowLive.Index, :edit

      live "/assets-shadow/:id", Admin.AssetLive.AssetShadowLive.Show, :show
      live "/assets-shadow/:id/show/edit", Admin.AssetLive.AssetShadowLive.Show, :edit
    end
  end

  scope "/api" do
    pipe_through [:browser, :require_authenticated_user]

    get "/graphiql", ItsmWeb.GraphiqlController, :index
  end

  scope "/api" do
    pipe_through [:api, ItsmWeb.Plugs.ApiAuth]

    forward "/graphql", Absinthe.Plug, schema: Itsm.Graphql.Schema
  end
end
