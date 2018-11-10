defmodule AzureADOpenId.NonceStore do
  @moduledoc """
  Creates, stores and checks nonces. A created nonce will be deleted after it's timeout elapses.
  """
  use Agent
  @agent_name __MODULE__

  def start_link(_) do
    Agent.start_link(fn -> MapSet.new end, name: @agent_name)
  end

  def create_nonce(timeout) do
    # create nonce
    nonce = SecureRandom.uuid
    Agent.update(@agent_name, &MapSet.put(&1, nonce))

    # set cleanup task
    if(timeout != :infinity) do
      Task.start(fn () -> cleanup(nonce, timeout) end)
    end

    nonce
  end

  def check_nonce(nonce) do
    deleted = Agent.get(@agent_name, &MapSet.member?(&1, nonce))
    delete_nonce(nonce)
    deleted
  end

  defp cleanup(nonce, timeout) do
    Process.sleep(timeout)
    delete_nonce(nonce)
  end

  defp delete_nonce(nonce) do
    Agent.update(@agent_name, &MapSet.delete(&1, nonce))
  end
end
