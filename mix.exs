defmodule ExSepa.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_sepa,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "ExSepa",
      source_url: "https://github.com/Lehrstuhl-BWL-EvIS/ex_sepa",
      homepage_url: "https://github.com/Lehrstuhl-BWL-EvIS/ex_sepa",
      docs: [
        # The main page in the docs
        # main: "ExSepa",
        # logo: "path/to/logo.png",
        extras: ["README.md", "LICENSE"]
      ]
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
      # Linter for better code consistency
      # https://hexdocs.pm/credo/overview.html
      # https://github.com/rrrene/credo
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},

      # Generates the documentation for the entire project
      # https://hexdocs.pm/ex_doc/readme.html
      # https://github.com/elixir-lang/ex_doc
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Generates fake data (primarily for the seed)
      # https://hexdocs.pm/faker/readme.html
      # https://github.com/elixirs/faker
      {:faker, "~> 0.18", only: [:dev, :test]}
    ]
  end
end
