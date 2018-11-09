defmodule AzureADOpenId.NonceStore do
  @moduledoc """
  Creates, stores and checks nonces. A created nonce will be deleted after it's timeout elapses.
  """

  @tid __MODULE__

  def create_nonce(timeout) do
    init_table()

    # create nonce
    nonce = SecureRandom.uuid
    :ets.insert(@tid, {nonce})

    # set cleanup task
    if(timeout != :infinity) do
      Task.start(fn () -> cleanup(nonce, timeout) end)
    end

    nonce
  end

  def check_nonce(nonce) do
    init_table()
    nonce_list = :ets.take(@tid, nonce)

    case nonce_list do
      [{^nonce}] -> true
      _ -> false
    end
  end

  defp init_table do
    tid = :ets.whereis(__MODULE__)

    case tid do
      :undefined -> :ets.new(__MODULE__, [:public, :named_table])
      tid -> tid
    end
  end

  defp cleanup(nonce, timeout) do
    Process.sleep(timeout)
    :ets.delete(@tid, nonce)
  end
end
