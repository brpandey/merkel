defmodule Merkel.BinaryNode do

  alias Merkel.BinaryNode, as: Node

  # The node has a hash, the original key, two children and a height field
  defstruct key_hash: nil, search_key: nil, key: nil, value: nil, height: -1, left: nil, right: nil
  
  @display_first_n_bytes 8

  @doc "Provides dump of node info to be used in Inspect protocol implementation"

  def info(%Node{key_hash: nil}), do: {nil}
  def info(%Node{} = node) do
    {node.key_hash, node.search_key, node.height, node.left, node.right}
  end

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
