use Mix.Config

if Mix.env == :test && File.exists?("config/test.secret.exs") do
  import_config "test.secret.exs"
end
