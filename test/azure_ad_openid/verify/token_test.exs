defmodule CallbackTest do
  alias AzureADOpenId.NonceStore
  alias AzureADOpenId.Verify
  use ExUnit.Case

  @test_data Application.get_env(:azure_ad_openid, :test_data)

  import Mock

  setup_with_mocks [
    {NonceStore, [:passthrough], [check_nonce: fn nonce -> nonce == @test_data[:nonce] end ]},
    {System, [:passthrough], [system_time: fn(:second) -> @test_data[:now] end ]}
  ] do
    :ok
  end

  @tag :requires_secret_config
  test "callback" do
    config = Application.get_env(:azure_ad_openid, AzureADOpenId)
    id_token = @test_data[:id_token]
    code = @test_data[:code]

    claims = Verify.Token.id_token!(id_token, code, config)

    assert claims.nonce == @test_data[:nonce]
  end
end
