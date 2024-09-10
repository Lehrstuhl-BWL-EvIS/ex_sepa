defmodule ExSepa.GroupHeader do
  alias ExSepa.Validation

  @moduledoc false
  # """
  # Group Header: Set of characteristics shared by all individual transactions included in the message.
  # """

  @enforce_keys [:msg_id, :initiating_party_name]
  @typedoc false
  @type t :: %__MODULE__{
          msg_id: String.t(),
          initiating_party_name: String.t()
        }
  defstruct [:msg_id, :initiating_party_name]

  @doc false
  # """
  # The map has the following keys:
  #   * `:msg_id` - Message Identification: Point to point reference, assigned by the instructing party and sent to the next party in the chain, to unambiguously identify the message (maximum length of 35 characters).
  #   * `:initiating_party_name`- Initiating Party Name: Name by which a party is known and which is usually used to identify that party (maximum length of 70 characters).
  # """
  @spec new(%{
          msg_id: String.t(),
          initiating_party_name: String.t()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(%{msg_id: msg_id, initiating_party_name: initiating_party_name})
      when is_binary(msg_id) and is_binary(initiating_party_name) do
    with {:ok, new_msg_id} <- Validation.max_text(:msg_id, msg_id, 35),
         {:ok, new_initiating_party_name} <-
           Validation.max_text(:initiating_party_name, initiating_party_name, 70) do
      {:ok, %__MODULE__{msg_id: new_msg_id, initiating_party_name: new_initiating_party_name}}
    end
  end

  def new(group_header_map) do
    missing_keys = @enforce_keys -- Map.keys(group_header_map)

    if missing_keys == [] do
      with :ok <-
             Validation.text(
               [
                 {:msg_id, group_header_map[:msg_id]},
                 {:initiating_party_name, group_header_map[:initiating_party_name]}
               ],
               "Parameters must be strings."
             ) do
        {:error, "Something has gone wrong: #{group_header_map}"}
      end
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end
end

defmodule ExSepa.GroupHeaderError do
  @moduledoc false
  defexception [:message]
end
