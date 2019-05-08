defmodule ClientCredentialsTest do
  use ExUnit.Case
  alias AzureADOpenId.NonceStore
  alias AzureADOpenId.Client.ClientCredentials

  setup do
    {:ok, nonce_store} = NonceStore.start_link([])
    %{nonce_store: nonce_store}
  end

  test "get token" do
    access_token =
      Application.get_env(:azure_ad_openid, AzureADOpenId)
      |> ClientCredentials.get_token!()

    access_token
    |> AzureADOpenId.Callback.validate_access_token()
    |> IO.inspect()
  end
end
