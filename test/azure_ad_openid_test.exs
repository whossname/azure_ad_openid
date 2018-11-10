defmodule AzureAdOpenIdTest do
  use ExUnit.Case
  alias AzureADOpenId.NonceStore

  setup do
    {:ok, nonce_store} = NonceStore.start_link([])
    %{nonce_store: nonce_store}
  end

  test "build logout url" do
    config = [tenant: "tenant", client_id: "client_id"]
    actual = AzureADOpenId.logout_url(config)
    expected = "https://login.microsoftonline.com/tenant/oauth2/logout?client_id=client_id"
    assert actual == expected
  end

  test "authorize_url!" do
    redirect_uri = "http://localhost:4000/callback"
    config = [
      client_id: "client_id",
      tenant: "tenant"
    ]
    "https://login.microsoftonline.com/tenant/oauth2/authorize?client_id=client_id&nonce="
    <> rest
    = AzureADOpenId.authorize_url!(redirect_uri, config)

    <<nonce :: binary-size(36)>> <>
      "&redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fcallback&response_mode=form_post" <>
        "&response_type=code+id_token" = rest

    <<a :: binary-size(8)>> <> "-" <>
    <<b :: binary-size(4)>> <> "-" <>
    <<c :: binary-size(4)>> <> "-" <>
    <<d :: binary-size(4)>> <> "-" <>
    <<e :: binary-size(12)>> = nonce

    [a, b, c, d, e]
    |> Enum.map(&String.to_integer(&1, 16))

    assert NonceStore.check_nonce(nonce)
    assert !NonceStore.check_nonce(nonce)
  end
end
