defmodule Merkel.BinaryHashTree do

  alias Merkel.BinaryHashTree, as: BHTree
  alias Merkel.BinaryNode, as: BNode
 
  @children_per_node 2

  defstruct size: nil, root: nil, index: %{}

  # Public helper routine to get merkle tree (root) hash
  def tree_hash(%BHTree{root: nil}), do: nil
  def tree_hash(%BHTree{root: root}), do: root.key_hash 

  def hash(str) do
    :crypto.hash(:sha256, str) |> Base.encode16(case: :lower)
  end


  # Use decrement and compare algorithm
  # We use Bitwise for operations on the bit level
  def power_of_2?(0), do: false
  def power_of_2?(x) when x > 0 do
    import Bitwise, only: [&&&: 2] 

    # For Example
    # Positive cases:                      Negative cases
    # x 	      x – 1 	  x & (x – 1)      x 	      x – 1 	  x & (x – 1)
    # 00000001 	00000000 	00000000         00000011 	00000010 	00000010
    # 00000100 	00000011 	00000000         00000110 	00000101 	00000100
    # 00010000 	00001111 	00000000         00001011 	00001010 	00001010

    0 == (x &&& (x - 1))
  end



  # Create static tree given static list of {k,v} pairs
  # List must be a power of 2
  def create([]), do: raise "List can not be empty"
  def create(tuple_list) when is_list(tuple_list) and is_tuple(hd(tuple_list)) do

    size = Enum.count(tuple_list)

    # Size must be a power of two
    if not(power_of_2?(size)), do: raise "List size must be power of 2"
    

    # Sort the list by the 0th element of each tuple the key
    list = List.keysort(tuple_list, 0) 

    # Create tree recursively
    root = Enum.map(list, &leaf/1) |> create_level

    %BHTree{size: size, root: root}
  end


  defp create_level([{root, _acc}]), do: root
  defp create_level(children) when is_list(children) do

    # 1) Chunk children into sibling groups
    # 2) Create parents list for each sibling group (e.g. inner nodes)
    # 3) Recurse - this level's parents become the next level's children

    children 
    |> Enum.chunk_every(@children_per_node) # 1
    |> Enum.map(fn [{l, l_acc}, {r, r_acc}] -> 
      inner(l, r, {l_acc, r_acc})
    end) # 2
    |> create_level # 3
  end


  # Create leaf node
  defp leaf({k,v}) when is_binary(k) do 
    node = %BNode{key_hash: hash(k), search_key: k, key: k, value: v, height: 0} 

    # Along with the node we pass the largest key from the left subtree 
    # (since it's nil we use the key)
    {node, k}
  end

  # Create inner node
  defp inner(%BNode{} = left, %BNode{} = right, {l_lkey, r_lkey} = _largest_acc) do
    node = %BNode{
      key_hash: hash(left.key_hash <> right.key_hash),
      search_key: l_lkey, # we use the largest key from the left subtree as the search key
      height: Kernel.max(left.height, right.height) + 1,
      left: left, right: right
    }

    # we pass on the largest key from the right subtree to be used as a search key
    # for an inner node at a higher level
    {node, r_lkey}
  end

    
  @doc "Provides dump of tree info to be used in Inspect protocol implementation"
  def info(%BHTree{root: r} = tree) do
    {tree.size, BNode.info(r)} # Ensures root hash is fully visible
  end


  ##############################################################################
  # Inspect Protocol implementation -- custom behavior when inspect is invoked
  

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra
    
    def inspect(t, opts) do
      info = Inspect.Tuple.inspect(BHTree.info(t), opts)
      concat ["#Merkel.Tree<", info, ">"]
    end
  end


end
