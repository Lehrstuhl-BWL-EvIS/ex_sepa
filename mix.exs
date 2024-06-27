defmodule ExSepa.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_sepa,
      version: "0.1.0",
      elixir: "~> 1.16",
      # :prod
      start_permanent: Mix.env() == :test,
      deps: deps(),

      # Docs
      name: "ExSepa",
      source_url: "https://github.com/Lehrstuhl-BWL-EvIS/ex_sepa",
      homepage_url: "https://github.com/Lehrstuhl-BWL-EvIS/ex_sepa",
      docs: [
        # The main page in the docs
        # main: "ExSepa",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
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

      # Validator for IBAN account and BIC numbers
      # https://hexdocs.pm/bankster/api-reference.html
      # https://github.com/railsmechanic/bankster
      {:bankster, "~> 0.4.0"},

      # Generates fake data (primarily for the seed)
      # https://hexdocs.pm/faker/readme.html
      # https://github.com/elixirs/faker
      {:faker, "~> 0.18", only: [:dev, :test]},

      # An Elixir library for building XML
      # https://hexdocs.pm/xml_builder/
      # https://github.com/joshnuss/xml_builder
      {:xml_builder, "~> 2.3"}
    ]
  end
end
