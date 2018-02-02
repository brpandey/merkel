defmodule Merkel.Mixfile do
  use Mix.Project

  def project do
    [
      app: :merkel,
      version: "0.5.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
      ],
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.7.4", only: [:test], runtime: false},
    ]
  end
end
