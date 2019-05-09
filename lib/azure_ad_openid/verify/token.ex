defmodule AzureADOpenId.Verify.Token do
  @moduledoc """
  Runs validation on the claims for Azure Active Directory claims.
  """

  alias AzureADOpenId.Enforce
  alias AzureADOpenId.PublicKey
  alias AzureADOpenId.Verify.Claims

  def id_token!(id_token, code, config) do
    claims = verify_token(id_token)

    claims
    |> Claims.code_hash!(code)
    |> Claims.common!(config)
    |> Claims.id_token!(config)
  end

  def access_token!(access_token, config) do
    claims = verify_token(access_token)

    claims
    |> Claims.common!(config)
    |> Claims.access_token!(config)
  end

  defp verify_token(token) do
    opts = %{
      alg: "RS256",
      key: PublicKey.from_token(token)
    }

    token
    |> JsonWebToken.verify(opts)
    |> Enforce.ok!("JWT verification failed")
  end
end
