# ExSepa

> ⚠️ Work in progress, not ready for production ⚡

ExSepa is an Elixir library for generating SEPA direct debits.
The first release supports only SEPA Core Direct Debits.
Generated XML data is validated against the XML Schema Definition (XSD) provided by the German Banking Industry.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `ex_sepa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_sepa, "~> 0.1.0"}
  ]
end
```

## Documentation

Once published, the docs can be found at <https://hexdocs.pm/ex_sepa>.
