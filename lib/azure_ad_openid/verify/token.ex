defmodule AzureADOpenId.Verify.Token do
  @moduledoc """
  Runs validation on the claims for Azure Active Directory claims.
  """

  alias AzureADOpenId.PublicKey
  alias AzureADOpenId.Verify.Claims

  def id_token!(id_token, code, config) do
    claims = verify_token(id_token, config)

    claims
    |> Claims.code_hash!(code)
    |> Claims.common!(config)
    |> Claims.id_token!(config)
  end

  def access_token!(%{"access_token" => access_token}, config) do
    access_token!(access_token, config)
  end

  def access_token!(access_token, config) do
    claims = verify_token(access_token, config)

    claims
    |> Claims.common!(config)
    |> Claims.access_token!(config)
  end

  defp verify_token(token, config) do
    aud = config[:aud] || config[:client_id] || "00000002-0000-0000-c000-000000000000"

    opts = %{
      alg: "RS256",
      aud: aud,
      key: PublicKey.from_token(token),
      iss: "https://sts.windows.net/#{config[:tenant]}/"
    }

    token
    |> JWT.verify(opts)
    |> case do
      {:ok, map} ->
        map

      {:error, failed_claims} ->
        raise("JWT verification failed. Failed claims: #{inspect(failed_claims)}")
    end
  end
end
