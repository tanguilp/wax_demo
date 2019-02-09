defmodule WaxDemoWeb.CredentialController do
  use WaxDemoWeb, :controller

  require Logger

  def index(conn, _params) do
    login = get_session(conn, :login)

    cred_ids = WaxDemo.User.get_keys(login)

    if cred_ids == [] do
      render(conn, "credential.html", login: login, with_webauthn: false)
    else
      challenge =
        Wax.new_authentication_challenge(
          Enum.map(cred_ids, fn {_login, cred_id, cose_key} -> {cred_id, cose_key} end),
          []
        )

      Logger.debug("Wax: generated authentication challenge #{inspect(challenge)}")

      conn
      |> put_session(:authentication_challenge, challenge)
      |> render("credential.html",
        login: login,
        with_webauthn: true,
        challenge: Base.encode64(challenge.bytes),
        rp_id: challenge.rp_id,
        user: login,
        cred_ids: Enum.map(cred_ids, fn {_login, cred_id, _cose_key} -> cred_id end)
      )
    end
  end

  def validate(conn, %{
        "webauthn" => %{
          "clientDataJSON" => client_data_json,
          "authenticatorData" => authenticator_data_b64,
          "sig" => sig_b64,
          "rawID" => raw_id_b64,
          "type" => "public-key"
        }
      }) do
    challenge = get_session(conn, :authentication_challenge)

    authenticator_data = Base.decode64!(authenticator_data_b64)

    sig = Base.decode64!(sig_b64)

    case Wax.authenticate(raw_id_b64, authenticator_data, sig, client_data_json, challenge) do
      {:ok, _} ->
        Logger.debug("Wax: successful authentication for challenge #{inspect(challenge)}")

        conn
        |> put_session(:authenticated, true)
        |> put_flash(:info, "Successfully authenticated with WebAuthn")
        |> redirect(to: "/me")

      {:error, _} = error ->
        Logger.debug("Wax: authentication failed with error #{inspect(error)}")

        conn
        |> put_flash(:error, "Authentication failed. Try another authenticator or fill password")
        |> index(%{})
    end
  end

  def validate(
        conn,
        %{"password" => %{"password" => "123456", "webauthn_support" => "true"}}
      ) do
    conn
    |> put_session(:authenticated, true)
    |> put_flash(:info, "Successfully authenticated")
    |> redirect(to: "/register_key")
  end

  def validate(
        conn,
        %{"password" => %{"password" => "123456", "webauthn_support" => "false"}}
      ) do
    conn
    |> put_session(:authenticated, true)
    |> put_flash(:info, "Successfully authenticated")
    |> put_flash(:error, "Your browser does not support WebAuthn")
    |> redirect(to: "/me")
  end

  def validate(conn, %{"password" => %{"password" => _}}) do
    conn
    |> put_flash(:error, "Invalid password. Have a coffe, and try again")
    |> index(%{})
  end
end
