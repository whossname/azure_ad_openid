defmodule AzureADOpenId.Client.ClientCredentials do
  @moduledoc """
  Oauth2 client for Azure Active Directory.
  """

  alias OAuth2.Client
  alias OAuth2.Strategy

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
      strategy: Strategy.ClientCredentials,
      client_id: config[:client_id],
      client_secret: config[:client_secret],
      token_url: "#{azure_base_url}/token"
    )
  end
end
