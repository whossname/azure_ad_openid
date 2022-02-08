defmodule AzureAdOpenid.MixProject do
  use Mix.Project
  @version "0.2.0"
  @url "https://github.com/whossname/azure_ad_openid"
  @maintainers ["Tyson Buzza"]

  def project do
    [
      app: :azure_ad_openid,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Azure Active Directory OpenID",
      description: "Azure Active Directory authentication using OpenID.",
      source_url: @url,
      homepage_url: @url,
      package: package(),
      deps: deps(),
      docs: docs(),

      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
      ]
    ]
  end

  def package do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{"GitHub" => @url},
      files: ~w(lib) ++ ~w(LICENSE.md mix.exs README.md)
    ]
  end

  def docs do
    [
      extras: ["README.md", "LICENSE.md"],
      source_ref: "v#{@version}",
      main: "readme"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {AzureADOpenId.NonceStore, []},
      extra_applications: [:logger, :oauth2]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:oauth2, "~> 2.0"},
      {:json_web_token, "~> 0.2.5"},
      {:jason, "~> 1.1"},
      {:secure_random, "~> 0.5"},
      {:httpoison, "~> 1.2"},

      # tools
      {:mock, "~> 0.3.3", only: :test},
      {:mix_test_watch, "~> 1.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
    ]
  end
end
