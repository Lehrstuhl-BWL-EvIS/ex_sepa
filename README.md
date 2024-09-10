# ExSepa

> ⚠️ Work in progress, not ready for production ⚡

ExSepa is an Elixir library that is used to create SEPA direct debits.
In the first version, only the use of SEPA core direct debits is available.
The generated XML data is validated with the XML schema definition of the German Banking Industry. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_sepa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_sepa, "~> 0.1.0"}
  ]
end
```

## Documentation

Once published, the docs can be found at <https://hexdocs.pm/ex_sepa>.
