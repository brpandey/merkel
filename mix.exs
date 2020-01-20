defmodule Merkel.Mixfile do
  use Mix.Project

  def project do
    [
      app: :merkel,
      version: "1.0.5",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls],
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp description() do
    """
    Implements a balanced, merkle binary hash tree.
    Merkle trees are a beautiful data structure for summarizing 
    and verifying data integrity. 
    """
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Bibek Pandey"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/brpandey/merkel",
        "Docs" => "https://hexdocs.pm/merkel/"
      }
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
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.7.4", only: [:test]},
      {:propcheck, "~> 1.2", only: [:test, :dev]}
    ]
  end
end
