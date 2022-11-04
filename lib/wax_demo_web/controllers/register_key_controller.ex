defmodule WaxDemoWeb.RegisterKeyController do
  use WaxDemoWeb, :controller

  require Logger

  def index(conn, _params) do
    case get_session(conn, :login) do
      login when is_binary(login) ->
        opts =
          if login == String.reverse(login),
            do: [
              attestation: "direct",
              trusted_attestation_types: [:basic, :uncertain, :attca, :anonca],
              # Disable to make it work with Chrome Virtual Authenticator
              # Do not disable it if you don't know what you're doing!!!!
              verify_trust_root: false
            ],
            else: []

        challenge = Wax.new_registration_challenge(opts)

        Logger.debug("Wax: generated attestation challenge #{inspect(challenge)}")

        conn
        |> put_session(:challenge, challenge)
        |> render("register_key.html",
          login: get_session(conn, :login),
          challenge: Base.encode64(challenge.bytes),
          rp_id: challenge.rp_id,
          user: login,
          attestation: challenge.attestation
        )

      nil ->
        redirect(conn, to: "/")
    end
  end

  def validate(conn, %{
        "key" => %{
          "attestationObject" => attestation_object_b64,
          "clientDataJSON" => client_data_json,
          "rawID" => raw_id_b64,
          "type" => "public-key"
        }
      }) do
    challenge = get_session(conn, :challenge)

    attestation_object = Base.decode64!(attestation_object_b64)

    case Wax.register(attestation_object, client_data_json, challenge) do
      {:ok, {authenticator_data, result}} ->
        Logger.debug(
          "Wax: attestation object validated with result #{inspect(result)} " <>
            " and authenticator data #{inspect(authenticator_data)}"
        )

        user = get_session(conn, :login)

        maybe_aaguid = Wax.AuthenticatorData.get_aaguid(authenticator_data)

        WaxDemo.User.register_new_cose_key(
          user,
          raw_id_b64,
          authenticator_data.attested_credential_data.credential_public_key,
          maybe_aaguid
        )

        conn
        |> put_flash(:info, "Key registered")
        |> redirect(to: "/me")

      {:error, e} = error ->
        Logger.debug("Wax: attestation object validation failed with error #{inspect(error)}")

        conn
        |> put_flash(:error, "Key registration failed (#{Exception.message(e)})")
        |> index(%{})
    end
  end
end
