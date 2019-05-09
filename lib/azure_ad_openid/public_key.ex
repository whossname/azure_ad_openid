defmodule AzureADOpenId.PublicKey do
  @moduledoc """
  Provides public key access for Azure Active directory Oauth.
  The public keys from the Microsoft openid configuration are fetched from the configuration
  endpoint. The appropriate key is selected using the x5t value from a token header.
  """

  alias JsonWebToken.Algorithm.RsaUtil
  alias AzureADOpenId.Enforce

  def from_token(token) do
    token
    |> get_x5t_from_token!()
    |> get_public_key()
  end

  defp get_x5t_from_token!(id_token) do
    error = "Failed to get x5t from token - invalid response"

    id_token
    # get token header
    |> String.split(".")
    |> List.first()
    # decode
    |> Base.url_decode64(padding: false)
    |> Enforce.ok!(error)
    |> Jason.decode!()
    # get x5t
    |> Map.get("x5t")
  end

  defp get_public_key(x5t) do
    jwks_uri!()
    |> get_discovery_keys!(x5t)
    |> get_pubilc_key_from_cert
    |> RsaUtil.public_key()
  end

  defp jwks_uri! do
    "https://login.microsoftonline.com/common/.well-known/openid-configuration"
    |> http_request!
    |> Jason.decode!()
    |> Map.get("jwks_uri")
  end

  defp get_discovery_keys!(url, x5t) do
    url
    |> http_request!
    |> Jason.decode!()
    |> Map.get("keys")
    |> Enum.filter(fn key -> key["x5t"] == x5t end)
    |> List.first()
    |> Map.get("x5c")
  end

  # always use the first x5t value
  defp get_pubilc_key_from_cert([cert | _]) do
    spki =
      "-----BEGIN CERTIFICATE-----\n#{cert}\n-----END CERTIFICATE-----\n"
      |> :public_key.pem_decode()
      |> hd
      |> :public_key.pem_entry_decode()
      |> elem(1)
      |> elem(7)

    :public_key.pem_entry_encode(:SubjectPublicKeyInfo, spki)
    |> List.wrap()
    |> :public_key.pem_encode()
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
