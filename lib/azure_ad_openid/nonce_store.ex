defmodule AzureADOpenId.NonceStore do
  @moduledoc """
  Creates, stores and checks nonces. A created nonce will be deleted after it's timeout elapses.
  """

  @table :azure_ad_openid_nonce_store_table

  require Logger
  def create_nonce(timeout) do
    init_table()

    # create nonce
    nonce = SecureRandom.uuid

    :ets.insert(@table, {nonce})

    :ets.whereis(:azure_ad_openid_nonce_store_table)
    |> inspect
    |> Logger.info

    # set cleanup task
    if(timeout != :infinity) do
      Task.start(fn () -> cleanup(nonce, timeout) end)
    end

    nonce
  end

  def check_nonce(nonce) do
    :ets.whereis(:azure_ad_openid_nonce_store_table)
    |> inspect
    |> Logger.info

    init_table()

    :ets.whereis(:azure_ad_openid_nonce_store_table)
    |> inspect
    |> Logger.info

    nonce_list = :ets.take(@table, nonce)

    "nonce_list" |> Logger.info
    nonce_list
    |> inspect
    |> Logger.info

    case nonce_list do
      [{^nonce}] -> true
      _ -> false
    end
  end

  defp init_table do
    tid = :ets.whereis(@table)

    case tid do
      :undefined -> :ets.new(@table, [:public, :named_table])
      tid -> tid
    end
  end

  defp cleanup(nonce, timeout) do
    Process.sleep(timeout)
    :ets.delete(@table, nonce)
  end
end
