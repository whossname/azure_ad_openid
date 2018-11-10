defmodule NonceStoreTest do
  alias AzureADOpenId.NonceStore
  use ExUnit.Case

  test "create and check nonce" do
    nonce = NonceStore.create_nonce(15000)
    assert NonceStore.check_nonce(nonce)
    assert !NonceStore.check_nonce(nonce)
  end

  test "check nonce that doesn't exist" do
    nonce = SecureRandom.uuid
    assert !NonceStore.check_nonce(nonce)
  end
  
  test "delete old nonce" do
    nonce = NonceStore.create_nonce(0)
    Process.sleep(1)
    assert !NonceStore.check_nonce(nonce)
  end

  test "handle infinite timeout" do
    nonce = NonceStore.create_nonce(:infinity)
    assert NonceStore.check_nonce(nonce)
    assert !NonceStore.check_nonce(nonce)
  end
end
