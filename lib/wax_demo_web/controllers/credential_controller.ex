defmodule WaxDemoWeb.CredentialController do
  use WaxDemoWeb, :controller

  require Logger

  def index(conn, _params) do
    case get_session(conn, :login) do
      <<_::binary>> = login ->
        login_with_username(conn, login)

      nil ->
        login_with_resident_key(conn)
    end
  end

  def validate(conn, %{
        "webauthn" => %{
          "clientDataJSON" => client_data_json,
          "authenticatorData" => authenticator_data_b64,
          "sig" => sig_b64,
          "rawID" => credential_id,
          "type" => "public-key",
          "userHandle" => maybe_user_handle_b64
        }
      }) do
    authenticator_data_raw = Base.decode64!(authenticator_data_b64)
    sig_raw = Base.decode64!(sig_b64)
    maybe_user_handle = if maybe_user_handle_b64 <> "", do: Base.decode64!(maybe_user_handle_b64)

    challenge = get_session(conn, :authentication_challenge)
    credentials_from_user_id = credentials_from_user_id(maybe_user_handle)

    cred_id_aaguid_mapping =
      get_session(conn, :cred_id_aaguid_mapping) ||
        cred_mapping_from_user_handle(maybe_user_handle)

    with {:ok, _} <-
           Wax.authenticate(
             credential_id,
             authenticator_data_raw,
             sig_raw,
             client_data_json,
             challenge,
             credentials_from_user_id
           ),
         :ok <- check_authenticator_status(credential_id, cred_id_aaguid_mapping, challenge) do
      Logger.debug("Wax: successful authentication for challenge #{inspect(challenge)}")

      conn =
        if get_session(conn, :login) do
          conn
        else
          [{_, login, _, _, _} | _] = WaxDemo.User.get_by_user_id(maybe_user_handle)

          put_session(conn, :login, login)
        end

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

  defp login_with_username(conn, username) do
    cred_ids = WaxDemo.User.get_by_username(username)

    if cred_ids == [] do
      render(conn, "credential.html", login: username, with_webauthn: false)
    else
      allow_credentials =
        for {_user_id, _login, cred_id, cose_key, _} <- cred_ids, do: {cred_id, cose_key}

      challenge = Wax.new_authentication_challenge(allow_credentials: allow_credentials)

      cred_id_aaguid_mapping =
        for {_user_id, _login, cred_id, _cose_key, maybe_aaguid} <- cred_ids, into: %{} do
          {cred_id, maybe_aaguid}
        end

      Logger.debug("Wax: generated authentication challenge #{inspect(challenge)}")

      conn
      |> put_session(:authentication_challenge, challenge)
      |> put_session(:cred_id_aaguid_mapping, cred_id_aaguid_mapping)
      |> render("credential.html",
        login: username,
        with_webauthn: true,
        challenge: Base.encode64(challenge.bytes),
        rp_id: challenge.rp_id,
        user: username,
        cred_ids: Enum.map(cred_ids, fn {_user_id, _login, cred_id, _cose_key, _} -> cred_id end)
      )
    end
  end

  defp login_with_resident_key(conn) do
    challenge = Wax.new_authentication_challenge()

    conn
    |> put_session(:authentication_challenge, challenge)
    |> render("credential.html",
      login: nil,
      with_webauthn: true,
      challenge: Base.encode64(challenge.bytes),
      rp_id: challenge.rp_id,
      cred_ids: []
    )
  end

  defp credentials_from_user_id(nil) do
    []
  end

  defp credentials_from_user_id(user_id) do
    for {_, _, cred_id, cose_key, _} <- WaxDemo.User.get_by_user_id(user_id) do
      {cred_id, cose_key}
    end
  end

  defp cred_mapping_from_user_handle(nil) do
    []
  end

  defp cred_mapping_from_user_handle(user_id) do
    for {_, _, cred_id, _, maybe_aaguid} <- WaxDemo.User.get_by_user_id(user_id), into: %{} do
      {cred_id, maybe_aaguid}
    end
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
