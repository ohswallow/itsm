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
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [
        {ItsmWeb.UserAuth, :redirect_if_user_is_authenticated},
        # 추가된 부분
        {ItsmWeb.UserAuth, :set_locale}
      ] do
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
        # 추가된 부분
        {ItsmWeb.UserAuth, :set_locale}
      ] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      # live "/categories", CategoryLive.Index
      # live "/categories/:id", CategoryLive.Show

      # live "/crews/all/:id", TeamLive.Show, :all

      # 내 크루 관리
      live "/crews", TeamLive.MyIndex, :index
      live "/crews/new", TeamLive.MyIndex, :new
      live "/crews/:id/edit", TeamLive.MyIndex, :edit

      # 전체 크루 검색
      live "/crews/all", TeamLive.AllIndex, :index

      # 상세 페이지 (공통)
      live "/crews/:id", TeamLive.Show, :show
      live "/crews/:id/member", TeamLive.Show, :member

      # 카테고리(SR 유형) 목록
      live "/categories", CategoryLive.List

      live "/approvals", ApprovalLive.List, :index
      # live "/approvals/:request_id/new-comment", ApprovalLive.List, :new_comment
      live "/approvals/:request_id/approve", ApprovalLive.List, :approve
      live "/approvals/:request_id/reject", ApprovalLive.List, :reject
      live "/approvals/:request_id/feedback", ApprovalLive.List, :feedback

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

      # 관리자 기능
      live "/admin/categories", CategoryLive.Index, :index
      live "/admin/categories/new", CategoryLive.Index, :new
      live "/admin/categories/:id/edit", CategoryLive.Index, :edit

      live "/admin/categories/:id", CategoryLive.Show, :show
      live "/admin/categories/:id/show/edit", CategoryLive.Show, :edit

      live "/admin/approvals", ApprovalLive.Index, :index
      live "/admin/approvals/new", ApprovalLive.Index, :new
      live "/admin/approvals/:id/edit", ApprovalLive.Index, :edit

      live "/admin/approvals/:id", ApprovalLive.Show, :show
      live "/admin/approvals/:id/show/edit", ApprovalLive.Show, :edit

      live "/admin/crews", CrewLive.Index, :index
      live "/admin/crews/new", CrewLive.Index, :new
      live "/admin/crews/:id/edit", CrewLive.Index, :edit

      live "/admin/crews/:id", CrewLive.Show, :show
      live "/admin/crews/:id/show/edit", CrewLive.Show, :edit

      live "/admin/members", MemberLive.Index, :index
      live "/admin/members/new", MemberLive.Index, :new
      live "/admin/members/:id/edit", MemberLive.Index, :edit

      live "/admin/members/:id", MemberLive.Show, :show
      live "/admin/members/:id/show/edit", MemberLive.Show, :edit

      live "/admin/comments", CommentLive.Index, :index
      live "/admin/comments/new", CommentLive.Index, :new
      live "/admin/comments/:id/edit", CommentLive.Index, :edit

      live "/admin/comments/:id", CommentLive.Show, :show
      live "/admin/comments/:id/show/edit", CommentLive.Show, :edit
    end
  end

  scope "/", ItsmWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [
        {ItsmWeb.UserAuth, :mount_current_user},
        # 추가된 부분
        {ItsmWeb.UserAuth, :set_locale}
      ] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
