defmodule AzureADOpenId.VerifyClaims do
  @moduledoc """
  Runs validation on the claims for Azure Active Directory claims.
  """

  alias AzureADOpenId.Enforce
  alias AzureADOpenId.NonceStore

  @iat_timeout 360 # 6 minutes

  def verify!(claims, code, config) do
    aud = config[:client_id] 
    tid = config[:tenant] 

    claims
    |> verify_code_hash!(code)
    |> validate_claims!(aud, tid)

    claims
  end

  defp verify_code_hash!(claims, code) do
    hash_actual = :crypto.hash(:sha256, code)

    hash_expected =
      claims[:c_hash]
      |> Base.url_decode64(padding: false)
      |> Enforce.ok!("Failed to decode c_hash")

    hash_length = byte_size(hash_expected)
    hash_actual = :binary.part(hash_actual, 0, hash_length)

    # validate hash
    (hash_length >= 8) # normally 16
    |> Enforce.true!("Invalid c_hash - too short")

    (hash_actual == hash_expected)
    |> Enforce.true!("Invalid c_hash - c_hash from id_token and code do not match")

    claims
  end

  require Logger
  defp validate_claims!(claims, expected_aud, expected_tid, iat_timeout \\ @iat_timeout) do
    now = System.system_time(:second)
    expected_iss = "https://sts.windows.net/#{expected_tid}/" 

    Enforce.true!([
      # audience
      {expected_aud == claims[:aud], "aud"},

      # tenant/issuer
      {expected_iss == claims[:iss], "iss"},
      {expected_tid == claims[:tid], "tid"},

      # time checks
      {now < claims[:exp], "exp"},
      {now >= claims[:nbf], "nbf"},
      {now >= claims[:iat], "iat"},
      {now <= claims[:iat] + iat_timeout, "iat"},

      # nonce
      {NonceStore.check_nonce(claims[:nonce]), "nonce"}
    ], "Invalid claim: ")

    claims
  end
end
