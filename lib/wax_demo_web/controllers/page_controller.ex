defmodule WaxDemoWeb.PageController do
  use WaxDemoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def login(conn, %{"login" => %{"login" => ""}}) do
    conn
    |> put_flash(:error, "Login cannot be empty")
    |> render("index.html")
  end

  def login(conn, %{"login" => %{"login" => login}}) do
    conn
    |> put_session(:login, login)
    |> redirect(to: "/credential")
  end
end
