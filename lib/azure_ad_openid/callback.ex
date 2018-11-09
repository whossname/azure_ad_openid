defmodule AzureADOpenId.Callback do
  @moduledoc """
  Provides the callback functions for Azure Active directory Oauth. 
  The public keys from the Microsoft openid configuration are fetched, and the appropriate key is
  selected using the x5t value from the returned token header. The public key is used to verify the
  token and then the returned code is used to verify the claims on the token.
  """

  alias JsonWebToken.Algorithm.RsaUtil
  alias AzureADOpenId.VerifyClaims
  alias AzureADOpenId.Enforce

  def process_callback!(id_token, code, config) do
    public_key =
      id_token
      |> get_x5t_from_token!
      |> get_public_key

    opts = %{
      alg: "RS256",
      key: public_key
    }

    id_token
    |> JsonWebToken.verify(opts)
    |> Enforce.ok!("JWT verification failed")
    |> VerifyClaims.verify!(code, config)
  end

  defp get_x5t_from_token!(id_token) do
    error = "Failed to get x5t from token - invalid response"

    id_token
    # get token header
    |> String.split(".")
    |> List.first
    # decode
    |> Base.url_decode64(padding: false)
    |> Enforce.ok!(error)
    |> Jason.decode!
    # get x5t
    |> Map.get("x5t")
  end

  defp get_public_key(x5t) do
    jwks_uri!()
    |> get_discovery_keys!(x5t)
    |> get_pubilc_key_from_cert
    |> RsaUtil.public_key
  end

  defp jwks_uri! do
    "https://login.microsoftonline.com/common/.well-known/openid-configuration"
    |> http_request!
    |> Jason.decode!
    |> Map.get("jwks_uri")
  end

  defp get_discovery_keys!(url, x5t)do
    url
    |> http_request!
    |> Jason.decode!
    |> Map.get("keys")
    |> Enum.filter(fn(key) -> key["x5t"] === x5t end)
    |> List.first
    |> Map.get("x5c")
  end

  # always use the first x5t value
  defp get_pubilc_key_from_cert([cert | _]) do
    spki =
      "-----BEGIN CERTIFICATE-----\n#{cert}\n-----END CERTIFICATE-----\n"
      |> :public_key.pem_decode
      |> hd
      |> :public_key.pem_entry_decode
      |> elem(1)
      |> elem(7)

    :public_key.pem_entry_encode(:SubjectPublicKeyInfo, spki)
    |> List.wrap
    |> :public_key.pem_encode
  end

  defp http_request!(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: code}} ->
        raise "HTTP request error. Status Code: #{code} URL: #{url}"
      {:error, error} ->
        raise error
    end
  end
end
