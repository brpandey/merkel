defmodule Merkel.BinaryHashTree do
  @moduledoc """
  Implements a merkle binary hash tree that is balanced using AVL 
  """

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node
  alias Merkel.AVL, as: AVL

  @children_per_node 2
  @display_tree_size_limit 64

  defstruct size: nil, root: nil

  # Public helper routine to get merkle tree (root) hash
  def tree_hash(%Tree{root: nil}), do: nil
  def tree_hash(%Tree{root: root}), do: root.key_hash 

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


  # Create tree given list of {k,v} pairs (fast, uses level order build) 
  # or create empty tree

  # List must be a power of 2

  def create(), do: %Tree{size: 0}
  def create([]), do: raise "List can not be empty"
  def create(tuple_list) when is_list(tuple_list) and is_tuple(hd(tuple_list)) do

    size = Enum.count(tuple_list)

    # Size must be a power of two
    if not(power_of_2?(size)), do: raise "List size must be power of 2"

    # Sort the list by the 0th element of each tuple the key
    list = List.keysort(tuple_list, 0) 

    # Create tree recursively
    root = Enum.map(list, &leaf_level/1) |> add_level

    %Tree{size: size, root: root}
  end


  @doc """
  Public insert method, adds leaf in O(log n) since the tree is balanced
  """

  def insert(%Tree{root: r} = tree, {k, v} = data) when is_binary(k) do
    
    leaf = leaf(data)
    
    # check to see if we already have the key, if so, don't increment size
    size = 
      case lookup(tree, k) do
        {:ok, _} -> tree.size
        {:error, _} -> tree.size + 1 # Not found, so add will increase size
      end

    root = add_node(r, leaf)

    # Update the passed back tree with the updated size
    %Tree{tree | root: root, size: size}
  end


  # Simple lookup routine O(log n) since tree is balanced
  def lookup(%Tree{root: r}, key), do: do_lookup(r, key)

  ###################
  # PRIVATE HELPERS #
  ###################


  ##############################################################################
  # Tree creation helpers

  # Helpers to create tree, one node at a time

  # Base Case - empty tree - pattern match on empty node
  # Hence the first root node is just a leaf node (not an inner node)
  defp add_node(nil, %Node{} = leaf), do: leaf

  # Leaf Node Cases (pattern matching the children nil)
  # 1) Keys match, so effectively replace the leaf node with this updated leaf node value
  # 2) Keys mismatch, create inner node with add leaf node and existing leaf node
  defp add_node(%Node{key: key, left: nil, right: nil}, 
                %Node{key: key, left: nil, right: nil} = add) do add end
  
  defp add_node(%Node{key: s_key, left: nil, right: nil} = node, 
           %Node{key: a_key} = add) do

    # Determine the children order of our new inner node and our new add leaf node
    case a_key > s_key do
      true -> inner(node, add, s_key)
      false -> inner(add, node, a_key)
    end
  end

  # Inner Node Case
  defp add_node(%Node{search_key: s_key, left: l, right: r} = n1, %Node{key: a_key} = add)
  when not(is_nil(l)) and not(is_nil(r)) do
    
    # We recursively call add which may return 
    # 1) the leaf node with the same key but updated value, or
    # 2) a new inner node with a new leaf
    # 3) an updated inner node
    {l, r} = 
      case a_key > s_key do
        true -> {l, add_node(r, add)}
        false -> {add_node(l, add), r}
      end

    # Update original node with possibly updated l or r child
    n2 = %Node{ n1 | left: l, right: r, height: Kernel.max(l.height, r.height) + 1}

    # Balance as necessary updating the hashes as fit (when an avl rotation is performed :))
    # If no balance required check to make sure if we need to update the current node hash
    case AVL.balance?(n2) do
      true -> AVL.balance(n2, a_key, &update_hash/1)
      false -> update_hash(n1, n2)
    end
  end


  # Helpers to create tree, level-wise

  defp add_level([{root, _acc}]), do: root
  defp add_level(children) when is_list(children) do

    # 1) Chunk children into sibling groups
    # 2) Create parents list for each sibling group (e.g. inner nodes)
    # 3) Recurse - this level's parents become the next level's children

    children 
    |> Enum.chunk_every(@children_per_node) # 1
    |> Enum.map(fn [{l, l_acc}, {r, r_acc}] -> 
      inner_level(l, r, {l_acc, r_acc})
    end) # 2
    |> add_level # 3
  end


  ##############################################################################
  # Node creation helpers
  

  # Create leaf node
  defp leaf({k,v}) when is_binary(k) do 
    %Node{key_hash: hash(k), search_key: k, key: k, value: v, height: 0} 
  end

  defp leaf_level({k,v}) when is_binary(k) do 
    # Along with the node we pass the largest key from the left subtree 
    # (since it's nil we use the key)
    {leaf({k,v}), k}
  end


  # Create inner node
  defp inner(%Node{} = l, %Node{} = r, s_key) when is_binary(s_key) do
    %Node{
      key_hash: hash_concat(l,r),
      search_key: s_key, 
      height: Kernel.max(l.height, r.height) + 1,
      left: l, right: r
    }
  end

  # Create inner node using level order create
  defp inner_level(%Node{} = l, %Node{} = r, {l_lkey, r_lkey} = _largest_acc) do

    # we use the largest key from the left subtree as the search key
    node = inner(l, r, l_lkey)
    # we pass on the largest key from the right subtree to be used as a search key
    # for an inner node at a higher level
    {node, r_lkey}
  end

  ##############################################################################
  # Lookup helpers

  defp do_lookup(nil, key), do: {:error, "key: #{key} not found in tree"}
  defp do_lookup(%Node{key: key, value: v}, key), do: {:ok, v}
  defp do_lookup(%Node{search_key: s_key, left: l, right: r}, key)
  when is_binary(key) do
    case key > s_key do
      true -> do_lookup(r, key)
      false -> do_lookup(l, key)
    end
  end


  ##############################################################################
  # Hash helpers

  def hash_concat(lh, rh) when is_binary(lh) and is_binary(rh), do: hash(lh <> rh)
  def hash_concat(%Node{} = l, %Node{} = r), do: hash(l.key_hash <> r.key_hash)

  # Update hash
  defp update_hash(%Node{left: l, right: r} = node)
  when not(is_nil(l)) and not(is_nil(r)) do
    h = hash_concat(l,r)
    Kernel.put_in(node.key_hash, h)
  end

  # No rehash required since the children have the same hash values, 
  # return the update node
  defp update_hash(
        %Node{left: %Node{key_hash: lh}, right: %Node{key_hash: rh}} = n,
        %Node{left: %Node{key_hash: lh}, right: %Node{key_hash: rh}} = update) do 
    update 
  end

  # Since the key hashes are different for the two versions, rehash the update node
  defp update_hash(
        %Node{left: %Node{key_hash: lh1}, right: %Node{key_hash: rh1}} = n,
        %Node{left: %Node{key_hash: lh2}, right: %Node{key_hash: rh2}} = update) do
    update_hash(update)
  end

  ##############################################################################

    
  @doc "Provides dump of tree info to be used in Inspect protocol implementation"
  def info(%Tree{size: size, root: nil}), do: nil do
  def info(%Tree{size: size, root: r} = tree) do
    case size <= @display_tree_size_limit do
      true -> {tree.size, Node.info(r)} # Ensures root hash is fully visible
      false -> {tree.size, {node.key_hash, node.height, "...", "..."}}
    end
  end


  ##############################################################################
  # Inspect Protocol implementation -- custom behavior when inspect is invoked
  

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra
    
    def inspect(t, opts) do
      info = Inspect.Tuple.inspect(Tree.info(t), opts)
      concat ["#Merkel.Tree<", info, ">"]
    end
  end


end
