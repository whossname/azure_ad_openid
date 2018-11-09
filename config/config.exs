use Mix.Config

if File.exists?(Mix.env == :test && "config/config.secret.exs") do
  import_config "test.secret.exs"
end
