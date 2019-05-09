defmodule ClientCredentialsTest do
  use ExUnit.Case
  alias AzureADOpenId.NonceStore
  alias AzureADOpenId.Strategy.ClientCredentials
  alias AzureADOpenId.Verify

  setup do
    {:ok, nonce_store} = NonceStore.start_link([])
    %{nonce_store: nonce_store}
  end

  test "get token" do
    config = Application.get_env(:azure_ad_openid, AzureADOpenId)

    access_token = ClientCredentials.get_token!(config)

    access_token
    |> Verify.Token.access_token!(config)
  end
end
