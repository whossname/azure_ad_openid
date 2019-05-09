defmodule AzureADOpenId.Strategy.ClientCredentials do
  @moduledoc """
  Oauth2 client credentials strategy for Azure Active Directory.
  """

  alias OAuth2.Client
  alias OAuth2.Strategy.ClientCredentials

  def get_token!(config) do
    resp =
    config
    |> build_client()
    |> OAuth2.Client.get_token!()

    resp.token.access_token
  end

  defp build_client(config) do
    azure_base_url = "https://login.microsoftonline.com/#{config[:tenant]}/oauth2"

    Client.new(
      strategy: ClientCredentials,
      client_id: config[:client_id],
      client_secret: config[:client_secret],
      token_url: "#{azure_base_url}/token"
    )
  end
end
