defmodule WaxDemoWeb.MeController do
  use WaxDemoWeb, :controller

  def index(conn, %{"logout" => _}) do
    conn
    |> configure_session(drop: true)
    |> clear_session()
    |> index(%{})
  end

  def index(conn, _params) do
    if get_session(conn, :authenticated) do
      login = get_session(conn, :login)

      keys = WaxDemo.User.get_keys(login)

      render(conn, "me.html", login: login, keys: keys)
    else
      redirect(conn, to: "/")
    end
  end
end
