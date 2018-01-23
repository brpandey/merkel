defmodule Merkel.BinaryHashTree do

  alias Merkel.BinaryHashTree, as: BHTree
  alias Merkel.BinaryNode, as: BNode

#  @type t :: %BHTree{ root: Merkel.BinaryNode.t, height: non_neg_integer}
 
  @children_per_node 2


  defstruct size: nil, root: nil, index: %{}

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


  # Create static tree given static list
  # List must be a power of 2
  def create([]), do: raise "List can not be empty"
  def create(list) when is_list(list) do

    size = Enum.count(list)

    # Size must be a power of two
    if not(power_of_2?(size)), do: raise "List size must be power of 2"
    
    # Create hashes list from original vector
    hashes = Enum.map(list, &hash/1)

    # Store list hashes by index
    index_map_by_hash = 
      hashes
      |> Enum.with_index # by default index starts at 0
      |> Enum.reduce(%{}, fn {k,v}, acc -> Map.put(acc, k, v) end)

    # Create tree recursively
    root = create_level(hashes)

    %BHTree{size: size, root: root, index: index_map_by_hash}
  end


  defp create_level([root]), do: root
  defp create_level(list) when is_list(list) and is_binary(hd(list)) do

    # 1) First create the leaves
    # 2) Then recursively create the inner nodes of the tree on up to the root

    list |> Enum.map(&leaf/1) |> create_level
  end


  defp create_level(children) when is_list(children) do

    # 1) Chunk children into sibling groups
    # 2) Create parents list for each sibling group (e.g. inner nodes)
    # 3) Recurse - this level's parents become the next level's children

    children 
    |> Enum.chunk_every(@children_per_node) # 1
    |> Enum.map(fn [l, r] -> inner(l, r) end) # 2
    |> create_level # 3
  end


  # Create leaf node
  defp leaf(hash) when is_binary(hash) do 
    %BNode{value: hash, height: 0} 
  end

  # Create inner node
  defp inner(%BNode{} = left, %BNode{} = right) do
    %BNode{
      value: hash(left.value <> right.value),
      height: Kernel.max(left.height, right.height) + 1,
      left: left, right: right
    }
  end

    
  @doc "Provides dump of tree info to be used in Inspect protocol implementation"
  def info(%BHTree{} = tree) do {tree.size, tree.root} end


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
