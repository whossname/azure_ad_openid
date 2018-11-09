defmodule AzureADOpenId.Client do
  @moduledoc """
  Oauth2 client for Azure Active Directory.
  """

  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode
  alias AzureADOpenId.NonceStore
  @timeout 15 * 60 * 1000 # 15 minutes

  def authorize_url!(callback_url, config) do
    params = %{
        response_mode: "form_post",
        response_type: "code id_token",
        nonce: NonceStore.create_nonce(@timeout)
      }

    callback_url
    |> build_client(config)
    |> Client.authorize_url!(params)
  end

  def authorize_url(client, params) do
    AuthCode.authorize_url(client, params)
  end

  defp build_client(callback_url, config) do
    Client.new([
      strategy: __MODULE__,
      client_id: config[:client_id],
      redirect_uri: callback_url,
      authorize_url: "https://login.microsoftonline.com/#{config[:tenant]}/oauth2/authorize",
      token_url: "https://login.microsoftonline.com/#{config[:tenant]}/oauth2/token"
    ])
  end
end
