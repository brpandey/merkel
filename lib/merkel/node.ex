defmodule Merkel.BinaryNode do

  alias Merkel.BinaryNode, as: Node

  # The node has a hash, a search_key, a height key
  # For leaf nodes the key and value fields are used, otherwise they are nil
  # For inner nodes the two child fields left and right are used, otherwise they are nil
  # This allows us to use pattern matching to select correct node type 
  # instead using an extra type field or creating two node types
  defstruct key_hash: nil, search_key: nil, key: nil, value: nil, height: -1, left: nil, right: nil
  
  @type t :: %__MODULE__{}

  @display_skey_first_n_bytes 2
  @display_hash_first_n_bytes 4

  @doc "Provides dump of node info for root node"
  @spec root_info(t) :: tuple
  def root_info(%Node{} = node) do
    <<search_head :: binary-size(@display_skey_first_n_bytes)>> <> _rest = node.search_key

    {node.key_hash, "<=#{search_head}..>", node.height, node.left, node.right}
  end


  @doc "Provides node info to be used in Inspect protocol implementation"
  @spec info(t) :: tuple
  def info(%Node{key_hash: nil}), do: {nil}

  # Inner node
  def info(%Node{key_hash: hash, left: l, right: r} = node)
  when is_binary(hash) and not(is_nil(l)) and not(is_nil(r)) do 

    # Truncate the hash so it's easier to read as well as the search key
    <<hash_head :: binary-size(@display_hash_first_n_bytes)>> <> _rest = hash
    <<search_head :: binary-size(@display_skey_first_n_bytes)>> <> _rest = node.search_key

    {"#{hash_head}..", "<=#{search_head}..>", node.height, node.left, node.right}
  end

  # Leaf node
  def info(%Node{key_hash: hash, left: nil, right: nil} = node) when is_binary(hash) do 

    # Truncate the hash so it's easier to read
    <<hash_head :: binary-size(@display_hash_first_n_bytes)>> <> _rest = hash

    {"#{hash_head}..", node.search_key, node.height}
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
