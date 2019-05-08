defmodule AzureADOpenId.Client do
  @moduledoc """
  Oauth2 client for Azure Active Directory.
  """

  alias OAuth2.Client
  alias OAuth2.Strategy
  alias AzureADOpenId.NonceStore

  @timeout 15 * 60 * 1000 # 15 minutes

  @spec authorize_url!(String.t, Keyword.t) :: String.t
  def authorize_url!(callback_url, config) do
    params = [
      response_mode: "form_post",
      response_type: "code id_token",
      nonce: NonceStore.create_nonce(@timeout)
    ]

    callback_url
    |> build_client(config)
    |> Client.authorize_url!(params)
  end

  def authorize_url(client, params) do
    Strategy.AuthCode.authorize_url(client, params)
  end

  defp build_client(callback_url, config) do
    azure_base_url = "https://login.microsoftonline.com/#{config[:tenant]}/oauth2"

    Client.new([
      strategy: __MODULE__,
      client_id: config[:client_id],
      redirect_uri: callback_url,
      authorize_url: "#{azure_base_url}/authorize",
      token_url: "#{azure_base_url}/token"
    ])
  end
end
