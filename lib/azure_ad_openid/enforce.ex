defmodule AzureADOpenId.Enforce do
  @moduledoc """
  Helper functions for enforcing some conditions. The functions raise errors if the conditions
  aren't met.

  Useful for enforcing claims validation and destructuring :ok atoms without breaking the pipe.
  """

  def true!([], _), do: true

  def true!([{head, condition_name} | rest], error) do
    true!(head, error <> condition_name)
    true!(rest, error)
  end

  def true!(val, error) do
    if val do
      true
    else
      raise error
    end
  end

  def ok!({:ok, value}, _), do: value
  def ok!(_, error), do: raise(error)
end
