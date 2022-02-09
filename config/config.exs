import Config

config :json_web_token,
  json_library: Jason

if Mix.env() == :test && File.exists?("config/test.secret.exs") do
  import_config "test.secret.exs"
end
