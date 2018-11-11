defmodule AzureADOpenId do
  @moduledoc """
  Azure Active Directory authentication using OpenID.
  """

  alias AzureADOpenId.Client
  alias AzureADOpenId.Callback

  @type uri :: String.t
  @type config_values :: {:tenant, String.t} | {:client_id, String.t}
  @type config :: nil | [config_values]
  @type id_token :: map()
  @type callback_response :: {:ok, id_token} | {:error, String.t, String.t}
  @type conn :: map() # Plug.Conn.t

  @doc """
  Get a redirect url for authorization using Azure Active Directory login.
  """
  @spec authorize_url!(uri, config) :: uri
  def authorize_url!(redirect_uri, config \\ nil) do
    config = config || get_config()
    Client.authorize_url!(redirect_uri, config)
  end

  @doc """
  Handles and validates the `t:id_token/0` in the callback response. The redirect_uri used in the 
  `authorize_url!/1` function should redirect to a path that uses this funtion.
  """
  @spec handle_callback!(conn, config) :: callback_response
  def handle_callback!(conn, config \\ nil) do
    config = config || get_config()

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

  @doc """
  Returns the redirect url for logging out of Azure Active Directory.
  """
  @spec logout_url(uri) :: uri
  def logout_url(redirect_uri) when is_binary(redirect_uri) do
    logout_url(get_config(), redirect_uri)
  end

  @doc """
  Returns the redirect url for logging out of Azure Active Directory.
  """
  @spec logout_url(config, uri | nil) :: uri
  def logout_url(config \\ nil, redirect_uri \\ nil) do
    config = config || get_config()

    tenant = config[:tenant]
    client_id = config[:client_id]

    url = "https://login.microsoftonline.com/#{tenant}/oauth2/logout?client_id=#{client_id}"

    if is_binary(redirect_uri) do
      redirect_uri = URI.encode_www_form(redirect_uri)
      url <> "?post_logout_redirect_uri=" <> redirect_uri
    else
      url
    end
  end

  @doc """
  Checks if the library is configured with the standard Elixir configuration (i.e. using
  the config files). 
  """
  @spec configured?() :: boolean()
  def configured?() do 
    configset = get_config() 
    configset != nil
    && Keyword.has_key?(configset, :tenant) 
    && Keyword.has_key?(configset, :client_id) 
  end 

  defp get_config() do
    Application.get_env(:azure_ad_openid, AzureADOpenId)
  end

  @doc """
  Returns a human readable user name from an `t:id_token/0`. This is useful as the 
  Azure Active Directory `t:id_token/0` can be very inconsistent in how user names are stored.
  """
  @spec get_user_name(id_token) :: String.t
  def get_user_name(token) do
    cond do
      token[:family_name] && token[:given_name] ->
        name = token[:given_name] <> " " <> token[:family_name] 
        format_name(name)
      token[:upn] -> format_name(token[:upn])
      token[:name] -> format_name(token[:name])
      token[:email] -> format_name(token[:email])
      true -> "No Name"
    end
  end

  defp format_name(name) do
    if should_format(name) do
      name
        |> String.split(["@", "_"])
        |> hd
        |> String.split([".", " "])
        |> Enum.map(&capitalize/1)
        |> Enum.join(" ")
    else
      name
    end
  end

  defp capitalize(name) do
    if has_upper?(name) do
      name
    else
      String.capitalize(name)
    end
  end

  @valid_upper String.graphemes("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  defp has_upper?(name), do: String.contains?(name, @valid_upper)

  defp should_format(name) do
    cond do
      String.contains?(name, [".", "@", "_"]) ->
        true
      has_upper?(name) ->
        false
      true ->
        true
    end
  end
end
