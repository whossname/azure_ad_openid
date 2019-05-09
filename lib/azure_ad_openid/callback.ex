defmodule AzureADOpenId.Callback do
  @moduledoc """
  Provides the callback functions for Azure Active directory Oauth.
  The public keys from the Microsoft openid configuration are fetched, and the appropriate key is
  selected using the x5t value from the returned token header. The public key is used to verify the
  token and then the returned code is used to verify the claims on the token.
  """

  alias AzureADOpenId.VerifyClaims
  alias AzureADOpenId.Enforce
  alias AzureADOpenId.PublicKey

  def process_callback!(id_token, code, config) do
    opts = %{
      alg: "RS256",
      key: PublicKey.from_token(id_token)
    }

    id_token
    |> JsonWebToken.verify(opts)
    |> Enforce.ok!("JWT verification failed")
    |> VerifyClaims.verify!(code, config)
  end

  def validate_access_token(access_token) do
    opts = %{
      alg: "RS256",
      key: PublicKey.from_token(access_token)
    }

    access_token
    |> JsonWebToken.verify(opts)
    |> Enforce.ok!("JWT verification failed")
  end
end
