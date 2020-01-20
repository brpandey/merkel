defmodule Merkel.BinaryHashTree do
  @moduledoc """
  Implements a merkle binary hash tree that is balanced using AVL rotations

  Supports create, lookup, keys, insert, delete operations

  Given an initial list of k-v pairs constructs an initial balanced
  tree without any initial rotations or initial rehashings

  Keys are binary, e.g. a utf8 encoded sequence of bytes (string) or just bytes
  Values are any type (use your discretion if you want the tree to be more compact)

  Keys and values are only stored in the leaves
  Inner nodes use the search_key value to determine order

  Hashes of the keys are stored in the node key_hash field
  Inner nodes store the concatenated hashes of their children in key_hash as well
  """

  import Merkel.Helper

  alias Merkel.AVL
  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node

  defstruct size: nil, root: nil

  @type t :: %__MODULE__{}
  @type key :: binary
  @type value :: any
  @type pair :: {key, value}

  @display_tree_size_limit 64

  @doc """
  Create balanced tree given a list of {k,v} pairs or create empty tree

  Given a list of atom key and binary value pairs, the atom options are
  :etf and :path to support creation from either a
  merkel etf binary or a file containing a merkel etf binary
  """
  @spec create(none | list) :: t | no_return
  def create(), do: %Tree{size: 0, root: nil}
  def create([]), do: create()

  def create([{k, _v} | _tail] = list) when is_binary(k) do
    {size, root} = create_tree(list)
    %Tree{size: size, root: root}
  end

  def create([{k, _v} | _tail] = opts) when is_atom(k) do
    # Upon the first successful fetch of either the erlang term format (etf) value
    # or path value, convert it to the Merkel term and halt

    Enum.reduce_while([:etf, :path], %Tree{} = create(), fn key, acc ->
      # If path, read the file path, set the value as the file binary and convert over
      # If etf, the value is already the merkel term in binary format, so convert it over
      case Keyword.fetch(opts, key) do
        {:ok, v} when is_binary(v) ->
          v =
            case key do
              :path -> File.read!(v)
              _ -> v
            end

          acc =
            case :erlang.binary_to_term(v) do
              %Tree{} = tree ->
                tree

              _ ->
                raise ArgumentError,
                      "Erlang Term Format does not contain a well-formed Merkel Tree term"
            end

          {:halt, acc}

        :error ->
          {:cont, acc}

        _ ->
          raise ArgumentError, "Unsupported option creation type or value"
      end
    end)
  end

  @doc """
  Returns key value pair if key lookup is successful
  """
  @spec lookup(t, key) :: {:ok, any} | {:error, String.t()}
  def lookup(%Tree{root: r}, key), do: get(r, key)

  @doc "Returns list of keys from bottom left of tree to bottom right"
  @spec keys(t) :: list
  def keys(%Tree{root: r}), do: do_traverse(r, :keys, []) |> Enum.reverse()

  @doc "Returns list of values from bottom left of tree to bottom right"
  @spec values(t) :: list
  def values(%Tree{root: r}), do: do_traverse(r, :values, []) |> Enum.reverse()

  @doc """
  Returns a list of the tree's key-value pairs in {k,v} tuple form.
  Pairs are extracted from the tree bottom left to bottom right.
  """
  @spec to_list(t) :: list
  def to_list(%Tree{root: r}), do: do_traverse(r, :to_list, []) |> Enum.reverse()

  @doc """
  Adds key value pair and then ensures tree is balanced.
  """
  @spec insert(t, pair) :: t
  def insert(%Tree{root: r} = tree, {k, _v} = data) when is_binary(k) do
    leaf = leaf(data)

    # check to see if we already have the key, if so, don't increment size
    size =
      case lookup(tree, k) do
        {:ok, _} ->
          tree.size

        # Not found, so add will increase size
        {:error, _} ->
          tree.size + 1
      end

    root = put(r, leaf)

    # Update the passed back tree with the updated size
    %Tree{tree | root: root, size: size}
  end

  @doc """
  Delete the specified key, ensuring it resides in the tree.  
  Updates binary tree search keys
  """
  @spec delete(t, key) :: {:ok, t} | {:error, String.t()}
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

        {:ok, %Tree{t | root: root, size: size - 1}}

      {:error, _} = msg ->
        msg
    end
  end

  @doc """
  Convert tree to erlang term format
  """
  @spec dump(t) :: binary
  def dump(%Tree{} = t), do: :erlang.term_to_binary(t)

  @doc """
  Store tree to file path p, in erlang term format
  """
  @spec store(t, binary) :: :ok | no_return()
  def store(%Tree{} = t, p) when is_binary(p), do: File.write!(p, dump(t))

  ###################
  # PUBLIC HELPERS #
  ###################

  # Public helper routine to get merkle tree (root) hash
  @spec tree_hash(nil | t) :: nil | binary
  def tree_hash(nil), do: nil
  def tree_hash(%Tree{root: nil}), do: nil
  def tree_hash(%Tree{root: root}), do: root.key_hash

  @spec size(nil | t) :: nil | non_neg_integer
  def size(nil), do: nil
  def size(%Tree{size: size}), do: size

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

  ###################
  # PRIVATE HELPERS #
  ###################

  # Helpers to create tree, one node at a time
  @spec put(Node.t() | nil, Node.t()) :: Node.t()

  # Base Case - empty tree - pattern match on empty node
  # Hence the first root node is just a leaf node (not an inner node)
  defp put(nil, %Node{} = leaf), do: leaf

  # Leaf Node Cases (pattern matching the children nil)
  # 1) Keys match, so effectively replace the leaf node with this updated leaf node value
  # 2) Keys mismatch, create inner node with add leaf node and existing leaf node
  defp put(%Node{key: key, left: nil, right: nil}, %Node{key: key, left: nil, right: nil} = add) do
    add
  end

  defp put(%Node{key: s_key, left: nil, right: nil} = node, %Node{key: a_key} = add) do
    # Determine the children order of our new inner node and our new add leaf node
    case a_key > s_key do
      true -> inner(node, add, s_key)
      false -> inner(add, node, a_key)
    end
  end

  # Inner Node Case
  defp put(%Node{search_key: s_key, left: l, right: r} = n1, %Node{key: a_key} = add)
       when not is_nil(l) and not is_nil(r) do
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
    n2 = %Node{n1 | left: l, right: r, height: Kernel.max(l.height, r.height) + 1}

    # Balance as necessary updating the hashes as fit (when an avl rotation is performed :))
    # If no balance required check to make sure if we need to update the current node hash
    case AVL.balance?(n2) do
      true -> AVL.balance(n2, a_key, &update_hash/1)
      false -> update_hash(n1, n2)
    end
  end

  ##############################################################################
  # Lookup helpers

  @spec get(nil | Node.t(), key) :: {:ok, value} | {:error, String.t()}
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
  @spec do_traverse(nil | Node.t(), atom, list) :: list
  defp do_traverse(nil, _option, acc), do: acc

  # Leaf cases, return either (key, value or {k,v}) prepended to acc.  Note, prepend is faster
  defp do_traverse(%Node{key: k, left: nil, right: nil}, :keys, acc), do: [k] ++ acc
  defp do_traverse(%Node{value: v, left: nil, right: nil}, :values, acc), do: [v] ++ acc
  defp do_traverse(%Node{key: k, value: v, left: nil, right: nil}, :to_list, acc), do: [{k,v}] ++ acc

  # Inner node case
  defp do_traverse(%Node{left: l, right: r}, option, acc)
  when not is_nil(l) and not is_nil(r) do
    acc = do_traverse(l, option, acc)
    do_traverse(r, option, acc)
  end


  ##############################################################################
  # Delete Node Helpers

  # NOTE: We don't rebalance after a delete since they are assumed infrequent

  # Base case - Leaf node which matches key (Key must reside in tree)
  @spec drop(Node.t(), key) :: nil | Node.t() | {Node.t(), key}
  defp drop(%Node{key: key, left: nil, right: nil}, key), do: nil

  # Inner node - Recurse to right subtree
  defp drop(%Node{search_key: s_key, left: l, right: r} = n, key)
       when not is_nil(l) and not is_nil(r) and key > s_key do
    # If we found the matching key and deleted it, remove this current node by replacing with the left child
    # Else, if we have an updated child, update it as the right child and recompute the hash value

    # In order to handle updating the search_keys higher up we add a second return param

    # Right subtree
    # If largest search_key is presented, We pass it on up
    case drop(r, key) do
      # n.search_key is now the largest search key given the subtree rooted at node n
      nil ->
        {l, n.search_key}

      %Node{} = x ->
        %Node{n | right: x} |> update_hash |> update_height

      {%Node{} = x, largest} ->
        {%Node{n | right: x} |> update_hash |> update_height, largest}
    end
  end

  # Inner node - Recurse to left subtree
  defp drop(%Node{search_key: s_key, left: l, right: r} = n, key)
       when not is_nil(l) and not is_nil(r) and key <= s_key do
    # If we found the matching key and deleted it, remove this current node by replacing with the right child
    # Else, if we have an updated child, update it as the left child and recompute the hash value

    # Left subtree
    # If largest search_key is presented, we consume it and don't pass it up
    case drop(l, key) do
      # Since we deleted on the left leaf we don't need to propagate a search key
      nil ->
        r

      %Node{} = x ->
        %Node{n | left: x} |> update_hash |> update_height

      {%Node{} = x, largest} ->
        %Node{n | search_key: largest, left: x} |> update_hash |> update_height
    end
  end

  # Update height
  @spec update_height(Node.t()) :: Node.t()
  defp update_height(%Node{left: l, right: r} = node)
       when not is_nil(l) and not is_nil(r) do
    h = Kernel.max(l.height, r.height) + 1
    Kernel.put_in(node.height, h)
  end

  ##############################################################################
  # Hash helpers

  # Update hash
  @spec update_hash(Node.t()) :: Node.t()
  defp update_hash(%Node{left: l, right: r} = node)
       when not is_nil(l) and not is_nil(r) do
    h = Merkel.Crypto.hash_concat(l, r)
    Kernel.put_in(node.key_hash, h)
  end

  # No rehash required since the children have the same hash values, 
  # return the update node
  @spec update_hash(Node.t(), Node.t()) :: Node.t()
  defp update_hash(
         %Node{left: %Node{key_hash: lh}, right: %Node{key_hash: rh}},
         %Node{left: %Node{key_hash: lh}, right: %Node{key_hash: rh}} = update
       ) do
    update
  end

  # Since the key hashes are different for the two versions, rehash the update node
  defp update_hash(
         %Node{left: %Node{key_hash: lh1}, right: %Node{key_hash: rh1}},
         %Node{left: %Node{key_hash: lh2}, right: %Node{key_hash: rh2}} = update
       )
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
      # Ensures root hash is fully visible
      true ->
        {tree.size, Node.root_info(r)}

      false ->
        {tree.size, {r.key_hash, r.height, "...", "..."}}
    end
  end

  # Allows users to inspect this module type in a controlled manner
  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.Tuple.inspect(Tree.info(t), opts)
      concat(["#Merkel.Tree<", info, ">"])
    end
  end
end
