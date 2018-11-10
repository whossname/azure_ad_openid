defmodule NonceStoreTest do
  alias AzureADOpenId.NonceStore
  use ExUnit.Case

  setup do
    {:ok, nonce_store} = NonceStore.start_link([])
    %{nonce_store: nonce_store}
  end

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

  test "create and check nonce async" do
    nonce =
      Task.async(fn () -> NonceStore.create_nonce(15000) end)
      |> Task.await()

    assert NonceStore.check_nonce(nonce)
    assert !NonceStore.check_nonce(nonce)
  end
end
