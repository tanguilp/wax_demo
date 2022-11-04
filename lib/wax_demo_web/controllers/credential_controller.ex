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
          Enum.map(cred_ids, fn {_login, cred_id, cose_key, _} -> {cred_id, cose_key} end)
        )

      cred_id_aaguid_mapping =
        for {_login, cred_id, _cose_key, maybe_aaguid} <- cred_ids, into: %{} do
          {cred_id, maybe_aaguid}
        end

      Logger.debug("Wax: generated authentication challenge #{inspect(challenge)}")

      conn
      |> put_session(:authentication_challenge, challenge)
      |> put_session(:cred_id_aaguid_mapping, cred_id_aaguid_mapping)
      |> render("credential.html",
        login: login,
        with_webauthn: true,
        challenge: Base.encode64(challenge.bytes),
        rp_id: challenge.rp_id,
        user: login,
        cred_ids: Enum.map(cred_ids, fn {_login, cred_id, _cose_key, _} -> cred_id end)
      )
    end
  end

  def validate(conn, %{
        "webauthn" => %{
          "clientDataJSON" => client_data_json,
          "authenticatorData" => authenticator_data_b64,
          "sig" => sig_b64,
          "rawID" => credential_id,
          "type" => "public-key"
        }
      }) do
    challenge = get_session(conn, :authentication_challenge)
    cred_id_aaguid_mapping = get_session(conn, :cred_id_aaguid_mapping)

    authenticator_data_raw = Base.decode64!(authenticator_data_b64)
    sig_raw = Base.decode64!(sig_b64)

    with {:ok, _} <-
           Wax.authenticate(
             credential_id,
             authenticator_data_raw,
             sig_raw,
             client_data_json,
             challenge
           ),
         :ok <- check_authenticator_status(credential_id, cred_id_aaguid_mapping, challenge) do
      Logger.debug("Wax: successful authentication for challenge #{inspect(challenge)}")

      conn
      |> put_session(:authenticated, true)
      |> put_flash(:info, "Successfully authenticated with WebAuthn")
      |> redirect(to: "/me")
    else
      {:error, e} ->
        conn
        |> put_flash(:error, "Authentication failed (error: #{Exception.message(e)})")
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

  defp check_authenticator_status(credential_id, cred_id_aaguid_mapping, challenge) do
    case cred_id_aaguid_mapping[credential_id] do
      nil ->
        :ok

      aaguid ->
        case Wax.Metadata.get_by_aaguid(aaguid, challenge) do
          {:ok, _} ->
            :ok

          {:error, _} = error ->
            error
        end
    end
  end
end
