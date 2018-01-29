defmodule Merkel.BinaryHashTree do
  @moduledoc """
  Implements a merkle binary hash tree that is balanced using AVL rotations
  
  Supports create, lookup, keys, insert, delete
  
  Given an initial list of k-v pairs constructs an initial balanced
  tree without any initial rotations or initial rehashings
  """
  
  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node
  alias Merkel.AVL, as: AVL
  
  
  defstruct size: nil, root: nil
  
  @type t :: %__MODULE__{}
  @type key :: String.t
  @type value :: any

  @type pair :: {key, value}


  @default_hash :sha256
  @hash_type Application.get_env(:merkel, :hash_algorithm)

  @display_tree_size_limit 64
  @hash_algorithms [:md5, :ripemd160, :sha, :sha224, :sha256, :sha384, :sha512]

  
  @doc """
  Create balanced tree given a list of {k,v} pairs or create empty tree
  """
  @spec create( none | list(pair)) :: t | no_return 
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
  Returns key value pair if key lookup is successful
  """
  @spec lookup(t, key) :: {:ok, any} | {:error, String.t}
  def lookup(%Tree{root: r}, key), do: get(r, key)


  @doc "Returns list of keys from bottom left of tree to bottom right"
  @spec keys(t) :: list
  def keys(%Tree{root: r}) do
    do_keys(r, []) |> Enum.reverse
  end


  @doc """
  Adds key value pair and then ensures tree is balanced.
  """
  @spec insert(t, pair) :: t
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
  
  @doc """
  Delete the specified key, ensuring it resides in the tree.  
  Updates binary tree search keys
  """
  @spec delete(t, key) :: {:ok, t} | {:error, String.t}
  def delete(%Tree{root: r, size: size} = t, key) when is_binary(key) do

    # Ensure the key resides in the tree, or pass back error tuple
    case lookup(t, key) do
      {:ok, _} -> 
        
        root = 
          case drop(r, key) do
            nil -> nil
            %Node{} = x -> x
            {%Node{} = x, _l} -> x
          end
        
        {:ok, %Tree{ t | root: root, size: size - 1} } 

      {:error, _} = msg -> msg
    end

  end


  ###################
  # PUBLIC HELPERS #
  ###################


  # Public helper routine to get merkle tree (root) hash
  @spec tree_hash(t) :: nil | String.t
  def tree_hash(%Tree{root: nil}), do: nil
  def tree_hash(%Tree{root: root}), do: root.key_hash 

  
  @spec hash(key) :: String.t
  def hash(str, type \\ @hash_type) do

    case type do
      t when t in @hash_algorithms -> 
        :crypto.hash(t, str) |> Base.encode16(case: :lower)
      _ -> # default case
        :crypto.hash(@default_hash, str) |> Base.encode16(case: :lower)
    end
  end

  @spec hash_concat(key | Node.t, key | Node.t) :: String.t
  def hash_concat(lh, rh) when is_binary(lh) and is_binary(rh), do: hash(lh <> rh)
  def hash_concat(%Node{} = l, %Node{} = r), do: hash(l.key_hash <> r.key_hash)


  ###################
  # PRIVATE HELPERS #
  ###################
  
  
  ##############################################################################
  # Tree creation helpers
  
  # Helpers to create a balanced tree from a list of sorted k-v pairs using partitioning
  # Used on setup
  
  # Divide number into its whole rough halves e.g. for 5 its 3 and 2
  @spec partition(non_neg_integer) :: {non_neg_integer, non_neg_integer}
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

  @spec partition_build(list(pair), non_neg_integer) :: tuple

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
  @spec put(Node.t | nil, Node.t) :: Node.t

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
  @spec leaf(pair) :: Node.t
  defp leaf({k,v}) when is_binary(k) do 
    %Node{key_hash: hash(k), search_key: k, key: k, value: v, height: 0} 
  end
  
  @spec leaf_level(pair) :: {Node.t, String.t}
  defp leaf_level({k,v}) when is_binary(k) do 
    # Along with the node we pass the largest key from the left subtree 
    # (since it's nil we use the key)
    {leaf({k,v}), k}
  end
  
  
  # Create inner node
  @spec inner(Node.t, Node.t, String.t) :: Node.t
  defp inner(%Node{} = l, %Node{} = r, s_key) when is_binary(s_key) do
    %Node{
      key_hash: hash_concat(l,r),
      search_key: s_key, 
      height: Kernel.max(l.height, r.height) + 1,
      left: l, right: r
    }
  end
  
  # Create inner node using level order create
  @spec inner_level(Node.t, Node.t, tuple) :: tuple
  defp inner_level(%Node{} = l, %Node{} = r, {l_lkey, r_lkey} = _largest_acc) do

    # we use the largest key from the left subtree as the search key
    node = inner(l, r, l_lkey)
    # we pass on the largest key from the right subtree to be used as a search key
    # for an inner node at a higher level
    {node, r_lkey}
  end
  
  ##############################################################################
  # Lookup helpers
  
  @spec get(nil | Node.t, key) :: {:ok, value} | {:error, String.t}
  defp get(nil, key), do: {:error, "key: #{key} not found in tree"}
  defp get(%Node{key: key, value: v}, key), do: {:ok, v}
  defp get(%Node{search_key: s_key, left: l, right: r}, key)
  when is_binary(key) do
    case key > s_key do
      true -> get(r, key)
      false -> get(l, key)
    end
  end


  # Helpers to retrieve key list

  # Base case nil node
  defp do_keys(nil, keys_acc), do: keys_acc

  # Leaf case, return key
  defp do_keys(%Node{key: k, left: nil, right: nil}, keys_acc) do
    [k] ++ keys_acc # prepend is faster
  end
  
  # Inner node case
  defp do_keys(%Node{left: l, right: r}, keys_acc)
  when not(is_nil(l)) and not(is_nil(r)) do
    acc = do_keys(l, keys_acc)
    do_keys(r, acc)
  end


  ##############################################################################
  # Delete Node Helpers

  # NOTE: We don't rebalance after a delete since they are assumed infrequent


  # Base case - Leaf node which matches key (Key must reside in tree)
  @spec drop(Node.t, key) :: nil | Node.t | {Node.t, key}
  defp drop(%Node{key: key, left: nil, right: nil}, key), do: nil

  # Inner node - Recurse to right subtree
  defp drop(%Node{search_key: s_key, left: l, right: r} = n, key)
  when not(is_nil(l)) and not(is_nil(r)) and key > s_key do

    # If we found the matching key and deleted it, remove this current node by replacing with the left child
    # Else, if we have an updated child, update it as the right child and recompute the hash value
    
    # In order to handle updating the search_keys higher up we add a second return param

    # Right subtree
    # If largest search_key is presented, We pass it on up
    case drop(r, key) do
      nil -> {l, n.search_key} # n.search_key is now the largest search key given the subtree rooted at node n
      %Node{} = x -> %Node{ n | right: x} |> update_hash
      {%Node{} = x, largest} -> { %Node{ n | right: x} |> update_hash, largest }
    end
  end


  # Inner node - Recurse to left subtree
  defp drop(%Node{search_key: s_key, left: l, right: r} = n, key)
  when not(is_nil(l)) and not(is_nil(r)) and key <= s_key do

    # If we found the matching key and deleted it, remove this current node by replacing with the right child
    # Else, if we have an updated child, update it as the left child and recompute the hash value
      
    # Left subtree
    # If largest search_key is presented, we consume it and don't pass it up
    case drop(l, key) do
      nil -> r # Since we deleted on the left leaf we don't need to propagate a search key
      %Node{} = x -> %Node{ n | left: x} |> update_hash
      {%Node{} = x, largest} -> %Node{ n | search_key: largest, left: x} |> update_hash
    end
  end
  
  ##############################################################################
  # Hash helpers
  
  
  # Update hash
  @spec update_hash(Node.t) :: Node.t
  defp update_hash(%Node{left: l, right: r} = node)
  when not(is_nil(l)) and not(is_nil(r)) do
    h = hash_concat(l,r)
    Kernel.put_in(node.key_hash, h)
  end
  
  # No rehash required since the children have the same hash values, 
  # return the update node
  @spec update_hash(Node.t, Node.t) :: Node.t
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
  @spec info(t) :: nil | tuple
  def info(%Tree{size: 0, root: nil}), do: {0, nil}
  def info(%Tree{size: size, root: r} = tree) when size > 0 do
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
