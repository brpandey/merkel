defmodule Merkel.BinaryNode do

  alias Merkel.BinaryNode, as: Node

  # The node has a value for the hash, two children and a height field
  defstruct value: nil, height: -1, left: nil, right: nil
  
  @display_first_n_bytes 8

  @doc "Provides dump of node info to be used in Inspect protocol implementation"
  def info(%Node{value: nil}), do: {nil}
  def info(%Node{value: hash} = node) when is_binary(hash) do 

    # Truncate the hash so it's easier to read
    <<head :: binary-size(@display_first_n_bytes)>> <> _rest = hash

    {"#{head}...", node.height, node.left, node.right}
  end
  
  
  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra
    
    def inspect(t, opts) do
      info = Inspect.Tuple.inspect(Node.info(t), opts)
      concat ["", info, ""]
    end
  end

end
