defmodule ItsmWeb.Router do
  # alias ItsmWeb.CategoryLive
  use ItsmWeb, :router

  import ItsmWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ItsmWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :fetch_cookies
    plug ItsmWeb.Plugs.SetLocale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ItsmWeb do
    pipe_through [:browser, :require_authenticated_user]

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
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {ItsmWeb.UserAuth, :redirect_if_user_is_authenticated},
        {ItsmWeb.UserAuth, :set_locale}
      ],
      layout: {ItsmWeb.Layouts, :default} do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ItsmWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {ItsmWeb.UserAuth, :ensure_authenticated},
        {ItsmWeb.UserAuth, :set_locale},
        {ItsmWeb.PathProvider, :set_current_path_on_assigns},
        {ItsmWeb.UserAuth, :log_menu_access}
      ],
      layout: {ItsmWeb.Layouts, :default} do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

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
      live "/categories/:id/common_k_create_vm/new", CommonKCreateVmLive.Form, :new
      live "/common_k_create_vm/:id", CommonKCreateVmLive.Show, :show
      live "/common_k_create_vm/:id/edit", CommonKCreateVmLive.Form, :edit
      live "/common_k_create_vm/:id/copy", CommonKCreateVmLive.Form, :copy

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

      live "/common_codes", Admin.CommonCodeLive.Index, :index
      live "/common_codes/new", Admin.CommonCodeLive.Index, :new
      live "/common_codes/:id/edit", Admin.CommonCodeLive.Index, :edit

      live "/common_codes/:id", Admin.CommonCodeLive.Show, :show
      live "/common_codes/:id/show/edit", Admin.CommonCodeLive.Show, :edit

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
    end
  end

  scope "/", ItsmWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [
        {ItsmWeb.UserAuth, :mount_current_user},
        {ItsmWeb.UserAuth, :set_locale}
      ],
      layout: {ItsmWeb.Layouts, :default} do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
