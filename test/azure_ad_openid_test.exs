defmodule AzureAdOpenIdTest do
  use ExUnit.Case

  test "build logout url" do
    actual = AzureAdOpenId.logout_url("tenant", "client_id")
    expected = "https://login.microsoftonline.com/tenant/oauth2/logout?client_id=client_id"
    assert actual == expected
  end
end
