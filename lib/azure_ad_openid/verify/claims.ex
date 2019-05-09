defmodule AzureADOpenId.Verify.Claims do
  @moduledoc """
  Runs validation on the claims for decrypted tokens.
  """

  alias AzureADOpenId.Enforce
  alias AzureADOpenId.NonceStore

  # 6 minutes
  @iat_timeout 360

  def code_hash!(claims, code) do
    hash_actual = :crypto.hash(:sha256, code)

    hash_expected =
      claims[:c_hash]
      |> Base.url_decode64(padding: false)
      |> Enforce.ok!("Failed to decode c_hash")

    hash_length = byte_size(hash_expected)
    hash_actual = :binary.part(hash_actual, 0, hash_length)

    # validate hash
    # normally 16
    (hash_length >= 8)
    |> Enforce.true!("Invalid c_hash - too short")

    (hash_actual == hash_expected)
    |> Enforce.true!("Invalid c_hash - c_hash from id_token and code do not match")

    claims
  end

  def id_token!(claims, config) do
    expected_aud = config[:client_id]

    Enforce.true!(
      [
        # audience
        {expected_aud == claims[:aud], "aud"},
        # nonce
        {NonceStore.check_nonce(claims[:nonce]), "nonce"}
      ],
      "Invalid claim: "
    )

    claims
  end

  def access_token!(claims, config) do
    expected_appid = config[:client_id]
    # oid
    # sub

    Enforce.true!(
      [
        # audience
        {expected_appid == claims[:appid], "appid"}
      ],
      "Invalid claim: "
    )

    claims
  end

  def common!(claims, config, iat_timeout \\ @iat_timeout) do
    expected_tid = config[:tenant]
    expected_iss = "https://sts.windows.net/#{expected_tid}/"
    now = System.system_time(:second)

    Enforce.true!(
      [
        # tenant/issuer
        {expected_iss == claims[:iss], "iss"},
        {expected_tid == claims[:tid], "tid"},

        # time checks
        {now < claims[:exp], "exp"},
        {now >= claims[:nbf], "nbf"},
        {now >= claims[:iat], "iat"},
        {now <= claims[:iat] + iat_timeout, "iat"}
      ],
      "Invalid claim: "
    )

    claims
  end
end
