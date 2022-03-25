defmodule WaxDemoWeb.Router do
  use WaxDemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {WaxDemoWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", WaxDemoWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/", PageController, :login

    get "/credential", CredentialController, :index
    post "/credential", CredentialController, :validate

    get "/me", MeController, :index

    get "/register_key", RegisterKeyController, :index
    post "/register_key", RegisterKeyController, :validate
  end
end
