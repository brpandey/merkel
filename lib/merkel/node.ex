defmodule Merkel.BinaryNode do

  alias Merkel.BinaryNode, as: Node

  # The node has a hash, a search_key, a height key
  # For leaf nodes the key and value fields are used, otherwise they are nil
  # For inner nodes the two child fields left and right are used, otherwise they are nil
  # This allows us to use pattern matching to select correct node type 
  # instead using an extra type field or creating two node types
  defstruct key_hash: nil, search_key: nil, key: nil, value: nil, height: -1, left: nil, right: nil
  
  @type t :: %__MODULE__{}

  @display_first_n_bytes 4

  @doc "Provides dump of node info to be used in Inspect protocol implementation"
  @spec info(t) :: tuple
  def info(%Node{key_hash: nil}), do: {nil}
  def info(%Node{} = node) do
    {node.key_hash, node.search_key, node.height, node.left, node.right}
  end

  @doc "Provides truncated dump of node info to be used in Inspect protocol implementation"
  @spec trunc_info(t) :: tuple
  def trunc_info(%Node{key_hash: nil}), do: {nil}
  def trunc_info(%Node{key_hash: hash} = node) when is_binary(hash) do 

    # Truncate the hash so it's easier to read
    <<head :: binary-size(@display_first_n_bytes)>> <> _rest = hash

    {"#{head}...", node.search_key, node.height, node.left, node.right}
  end
  
  
  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra
    
    def inspect(t, opts) do
      info = Inspect.Tuple.inspect(Node.trunc_info(t), opts)
      concat ["", info, ""]
    end
  end

end
