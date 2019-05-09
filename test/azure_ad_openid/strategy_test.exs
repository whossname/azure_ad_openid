defmodule ClientCredentialsTest do
  use ExUnit.Case
  alias AzureADOpenId.NonceStore
  alias AzureADOpenId.Strategy.ClientCredentials
  alias AzureADOpenId.Strategy.AuthCode
  alias AzureADOpenId.Verify

  @tag :requires_secret_config
  test "client credentials" do
    config = Application.get_env(:azure_ad_openid, AzureADOpenId)

    config
    |> ClientCredentials.get_token!()
    |> Verify.Token.access_token!(config)
  end

  @tag :requires_secret_config
  test "auth code" do
    config = Application.get_env(:azure_ad_openid, AzureADOpenId)

    "http://website/callback"
    |> AuthCode.authorize_url!(config)
    |> IO.inspect()
  end
end
