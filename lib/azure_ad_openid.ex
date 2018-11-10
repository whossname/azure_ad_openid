defmodule AzureADOpenId do
  @moduledoc """
  Documentation for AzureAdOpenid.
  """

  alias AzureADOpenId.Client
  alias AzureADOpenId.Callback

  def authorize_url!(redirect_uri),
    do: authorize_url!(redirect_uri, get_config())

  def authorize_url!(redirect_uri, config),
    do: Client.authorize_url!(redirect_uri, config)

  def handle_callback!(conn), do: handle_callback!(conn, get_config())

  def handle_callback!(conn, config) do
    case Map.get(conn, :params) do
      %{"id_token" => id_token, "code" => code} ->
        get_claims(id_token, code, config)
      %{"error" => error, "error_description" => error_description} ->
        {:error, error, error_description}
      _ ->
        {:error, "missing_code_or_token", "Missing code or id_token"}
    end
  end

  defp get_claims(id_token, code, config) do
    try do
      claims = Callback.process_callback!(id_token, code, config)
      {:ok, claims}
    rescue
      error in RuntimeError ->
        {:error, "failed_auth_callback", error.message}
    end
  end

  def logout_url(), do: logout_url(get_config())

  def logout_url(config) do
    tenant = config[:tenant]
    client_id = config[:client_id]
    "https://login.microsoftonline.com/#{tenant}/oauth2/logout?client_id=#{client_id}"
  end

  def configured?() do 
    configset = get_config() 
    configset != nil
    && Keyword.has_key?(configset, :tenant) 
    && Keyword.has_key?(configset, :client_id) 
  end 

  defp get_config() do
    Application.get_env(:azure_ad_openid, AzureADOpenId)
  end
end
