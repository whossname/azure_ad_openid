defmodule VerifyTest do
  alias AzureADOpenId.Verify.Claims
  alias AzureADOpenId.NonceStore
  use ExUnit.Case

  import Mock

  @code "0123456789abcdef"
  @client_id "example_client"
  @tenant "example_tenant"
  @nonce "example_nonce"
  @env_values [redirect_uri: "https://example.com", client_id: @client_id, tenant: @tenant]

  setup_with_mocks [
    {NonceStore, [:passthrough], [check_nonce: fn nonce -> nonce == @nonce end]}
  ] do
    :ok
  end

  def get_c_hash() do
    :crypto.hash(:sha256, @code)
    |> Base.url_encode64()
  end

  def build_claims do
    now = :os.system_time(:second)
    exp = now + 3600

    %{
      c_hash: get_c_hash(),
      iat: now,
      exp: exp,
      nbf: now,
      nonce: @nonce,
      aud: @client_id,
      tid: @tenant,
      iss: "https://sts.windows.net/#{@tenant}/"
    }
  end

  def assert_error(claims, msg) do
    try do
      claims
      |> Claims.code_hash!(@code)
      |> Claims.id_token!(@env_values)
      |> Claims.common!(@env_values)
    rescue
      e -> assert e.message == msg
    else
      _ -> assert false
    end
  end

  test "verify claims - valid" do
    claims = build_claims()

    claims_out =
      claims
      |> Claims.code_hash!(@code)
      |> Claims.id_token!(@env_values)

    assert claims_out == claims
  end

  test "verify claims - bad c_hash" do
    bad_code = "1123456789abcdef"

    bad_hash =
      :crypto.hash(:sha256, bad_code)
      |> Base.url_encode64()

    build_claims()
    |> Map.put(:c_hash, bad_hash)
    |> assert_error("Invalid c_hash - c_hash from id_token and code do not match")
  end

  test "verify claims - bad nonce" do
    build_claims()
    |> Map.put(:nonce, "bad nonce")
    |> assert_error("Invalid claim: nonce")
  end

  test "verify claims - bad audience" do
    build_claims()
    |> Map.put(:aud, "aud")
    |> assert_error("Invalid claim: aud")
  end

  test "verify claims - bad tid" do
    build_claims()
    |> Map.put(:tid, "tenant")
    |> assert_error("Invalid claim: tid")
  end

  test "verify claims - bad iss" do
    build_claims()
    |> Map.put(:iss, "iss")
    |> assert_error("Invalid claim: iss")
  end

  test "verify claims - bad iat" do
    build_claims()
    |> Map.put(:iat, 0)
    |> assert_error("Invalid claim: iat")
  end

  test "verify claims - bad iat future" do
    now = :os.system_time(:second)
    future = now * 2

    build_claims()
    |> Map.put(:iat, future)
    |> assert_error("Invalid claim: iat")
  end

  test "verify claims - bad exp" do
    build_claims()
    |> Map.put(:exp, 0)
    |> assert_error("Invalid claim: exp")
  end

  test "verify claims - bad nbf" do
    now = :os.system_time(:second)
    future = now * 2

    build_claims()
    |> Map.put(:nbf, future)
    |> assert_error("Invalid claim: nbf")
  end
end
