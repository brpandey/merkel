defmodule Merkel.BinaryHashTree do
  @moduledoc """
  Implements a merkle binary hash tree that is balanced using AVL rotations
  
  Supports lookup, insert methods
  
  Given an initial list of k-v pairs constructs an initial balanced
  tree without any initial rotations or initial rehashings
  """
  
  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node
  alias Merkel.AVL, as: AVL
  
  @display_tree_size_limit 64
  
  defstruct size: nil, root: nil
  
  # Public helper routine to get merkle tree (root) hash
  def tree_hash(%Tree{root: nil}), do: nil
  def tree_hash(%Tree{root: root}), do: root.key_hash 
  
  def hash(str) do
    :crypto.hash(:sha256, str) |> Base.encode16(case: :lower)
  end
  
  
  # Create balanced tree given a list of {k,v} pairs or create empty tree
  def create(), do: %Tree{size: 0}
  def create([]), do: raise "List can not be empty"
  def create([{k, _v} | _tail] = list) when is_binary(k) do
    # Sort the list by the 0th element of each tuple -> the key
    list = List.keysort(list, 0) 
    
    size = Enum.count(list)
    
    # Once finished the sorted list is reduced into a tree
    # signified by the tree root, with an empty consume list
    {{root, _kacc}, []} = partition_build(list, size)
    
    %Tree{size: size, root: root}
  end
  
  
  
  @doc """
  Public insert method, adds leaf in O(log n) since the tree is balanced
  """
  
  def insert(%Tree{root: r} = tree, {k, _v} = data) when is_binary(k) do
    
    leaf = leaf(data)
    
    # check to see if we already have the key, if so, don't increment size
    size = 
      case lookup(tree, k) do
        {:ok, _} -> tree.size
        {:error, _} -> tree.size + 1 # Not found, so add will increase size
      end
    
    root = put(r, leaf)
    
    # Update the passed back tree with the updated size
    %Tree{tree | root: root, size: size}
  end
  
  
  # Simple lookup routine O(log n) since tree is balanced
  def lookup(%Tree{root: r}, key), do: get(r, key)
  
  ###################
  # PRIVATE HELPERS #
  ###################
  
  
  ##############################################################################
  # Tree creation helpers
  
  # Helpers to create a balanced tree from a list of sorted k-v pairs using partitioning
  # Used on setup
  
  # Divide number into its whole rough halves e.g. for 5 its 3 and 2
  defp partition(n) when is_integer(n), do: {n - Kernel.div(n, 2), Kernel.div(n, 2)} 
  
  # We are able to build the leaves first of the merkle tree and then the inner structure
  # since we are using postorder traversal (leaves first then inner nodes)
  
  # The nice thing is the routine allows us to figure out 
  # the inner node structure in a balanced way (hence the partition divide by 2)
  
  # This can be represented in taking a number down to its halves for each level of
  # the tree until we get to 1
  
  # The children are roughly the integer halves of its parent
  # The number of leaves or 1's are equivalent to the root value (what we want :))
  
  #             5
  #            / \
  #           3   2
  #          / \ / \
  #         2  1 1  1
  #        / \
  #       1   1

  # So postorder traversal is 112131125
  # Exactly what we want as merkle tree key-values are stored at the leaves!
  
  # We thread the sorted list of values through all the 1's,
  # shrinking the list as it is consumed
  
  # We only create nodes until we get down to the 1's. Where we
  # we first create the leaf nodes, then when we have two leaf
  # nodes (l and r) we create the inner nodes.


  # Base case, e.g. empty list
  defp partition_build(list, 0) do
    {nil, list}
  end
  
  # Leaves case
  # From the diagram above the 1's are where the leaves go
  defp partition_build([head | tail], 1) when is_tuple(head) do
    {leaf_level(head), tail}
  end
  
  # Inner nodes case (all the inner nodes are values that are > 1)
  defp partition_build(list, size)
  when size > 1 and is_list(list) and is_tuple(hd(list)) do
    
    # Divide the size into its integer rough halves e.g. for 5 its 3 and 2
    {n1, n2} = partition(size)
    
    # Since it's postorder do left, then right followed by inner
    {{left, l_acc}, shrunk} = partition_build(list, n1)
    {{right, r_acc}, shrunk} = partition_build(shrunk, n2)
    
    inner = inner_level(left, right, {l_acc, r_acc})
    
    {inner, shrunk}
  end
  
  
  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
  
  # Helpers to create tree, one node at a time
  
  # Base Case - empty tree - pattern match on empty node
  # Hence the first root node is just a leaf node (not an inner node)
  defp put(nil, %Node{} = leaf), do: leaf
  
  # Leaf Node Cases (pattern matching the children nil)
  # 1) Keys match, so effectively replace the leaf node with this updated leaf node value
  # 2) Keys mismatch, create inner node with add leaf node and existing leaf node
  defp put(%Node{key: key, left: nil, right: nil}, 
           %Node{key: key, left: nil, right: nil} = add) do add end
  
  defp put(%Node{key: s_key, left: nil, right: nil} = node, 
           %Node{key: a_key} = add) do
    
    # Determine the children order of our new inner node and our new add leaf node
    case a_key > s_key do
      true -> inner(node, add, s_key)
      false -> inner(add, node, a_key)
    end
  end
  
  # Inner Node Case
  defp put(%Node{search_key: s_key, left: l, right: r} = n1, %Node{key: a_key} = add)
  when not(is_nil(l)) and not(is_nil(r)) do
    
    # We recursively call add which may return 
    # 1) the leaf node with the same key but updated value, or
    # 2) a new inner node with a new leaf
    # 3) an updated inner node
    {l, r} = 
      case a_key > s_key do
        true -> {l, put(r, add)}
        false -> {put(l, add), r}
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
  
  defp get(nil, key), do: {:error, "key: #{key} not found in tree"}
  defp get(%Node{key: key, value: v}, key), do: {:ok, v}
  defp get(%Node{search_key: s_key, left: l, right: r}, key)
  when is_binary(key) do
    case key > s_key do
      true -> get(r, key)
      false -> get(l, key)
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
        %Node{left: %Node{key_hash: lh}, right: %Node{key_hash: rh}},
        %Node{left: %Node{key_hash: lh}, right: %Node{key_hash: rh}} = update) do 
    update 
  end
  
  # Since the key hashes are different for the two versions, rehash the update node
  defp update_hash(
        %Node{left: %Node{key_hash: lh1}, right: %Node{key_hash: rh1}},
        %Node{left: %Node{key_hash: lh2}, right: %Node{key_hash: rh2}} = update) 
  when lh1 != lh2 or rh1 != rh2 do
    update_hash(update)
  end
  
  
  
  ##############################################################################
  # Inspect Protocol implementation -- custom behavior when inspect is invoked
  
  
  @doc "Provides dump of tree info to be used in Inspect protocol implementation"
  def info(%Tree{size: _size, root: nil}), do: nil
  def info(%Tree{size: size, root: r} = tree) do
    case size <= @display_tree_size_limit do
      true -> {tree.size, Node.info(r)} # Ensures root hash is fully visible
      false -> {tree.size, {r.key_hash, r.height, "...", "..."}}
    end
  end
  
  
  
  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra
    
    def inspect(t, opts) do
      info = Inspect.Tuple.inspect(Tree.info(t), opts)
      concat ["#Merkel.Tree<", info, ">"]
    end
  end
  
  
end
