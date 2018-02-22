defmodule Merkel.Audit do
  @moduledoc """
  Module facilitates audit proof creation given the candidate key
  as well as providing verification of the proof.

  The audit proof simply contains the candidate key and the audit path
  in tuple form that eliminates any need to store an index or other overhead
  to track key position.  The construction of the tuple encodes the proper
  hash concatenation order.

  "The purpose of the Merkle tree [in Bitcoin] is to allow the data in a block
  to be delivered piecemeal: a node can download only the header of a block 
  from one source, the small part of the tree relevant to them from another 
  source, and still be assured that all of the data is correct. 

  The reason why this works is that hashes propagate upward: if a malicious 
  user attempts to swap in a fake transaction into the bottom of a Merkle tree, 
  this change will cause a change in the node above, and then a change in the 
  node above that, finally changing the root of the tree and therefore the hash 
  of the block, causing the protocol to register it as a completely different block 
  (almost certainly with an invalid proof of work)"

  - Ethereum (https://github.com/ethereum/wiki/wiki/White-Paper#merkle-trees)
  """

  import Merkel.Crypto

  alias Merkel.Audit
  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node

  require Logger

  defstruct key: nil, path: nil

  @type t :: %__MODULE__{}

  @doc """
  Create audit proof
  This includes the set of sibling hashes in the path to the merkle root, 
  that will ensure verification
  """
  @spec create(nil | Tree.t(), Tree.key()) :: nil | t
  def create(nil, _key), do: nil
  def create(%Tree{root: nil}, key), do: %Audit{key: key, path: nil}

  def create(%Tree{root: %Node{} = root} = t, key) when is_binary(key) do
    case Tree.lookup(t, key) do
      {:ok, _} ->
        path = traverse(root, key, [], [])
        %Audit{key: key, path: path}

      {:error, _} ->
        %Audit{key: key, path: nil}
    end
  end

  @doc "Verify the candidate key and audit path are authenticated as part of the merkle tree"
  @spec verify(nil | t, String.t()) :: boolean
  def verify(nil, _th), do: nil
  def verify(%Audit{path: nil}, _th), do: false

  def verify(%Audit{key: key, path: trail}, tree_hash)
      when is_binary(key) and is_tuple(trail) and is_binary(tree_hash) do
    # Basically we walk through the list of audit hashes (trail) which represent
    # a distinct tree level

    # Given the nested tuple trail, we tail recurse to the leaf level 
    # using pattern matching, then create the hash accumulation
    acc_hash = prove(key, trail, [])

    acc_hash == tree_hash
  end

  #####################
  # Public helpers    #
  #####################

  @doc "Returns audit trail path length"
  @spec length(t | nil) :: non_neg_integer | nil
  def length(nil), do: nil
  def length(%Audit{path: nil}), do: 0

  def length(%Audit{path: path}) when is_tuple(path) do
    recursive_tuple_to_list(path) |> List.flatten() |> Enum.count()
  end

  #####################
  # Private functions #
  #####################

  # Convert recursive nested tuple into recursive nested list
  @spec recursive_tuple_to_list(tuple | binary) :: list | binary
  defp recursive_tuple_to_list(tuple) when is_tuple(tuple) do
    list = Tuple.to_list(tuple)
    Enum.map(list, &recursive_tuple_to_list/1)
  end

  defp recursive_tuple_to_list(x) when is_binary(x), do: x

  # Recursive traverse implementation which builds the audit hash verification trail
  # These are the sibling node hashes along the way from the leaf in question to the
  # merkle tree root.

  # We start from the root, and the trail is delivered backwards starting with leaf level
  @spec traverse(Node.t(), Tree.key(), list, list) :: tuple
  defp traverse(%Node{height: 0}, _key, audit_trail, pattern_trail)
       when is_list(audit_trail) and is_list(pattern_trail) do
    # Lists are from leaf level to next to root level

    # Combine the two lists so we can easily reduce to the audit patterned path
    # The audit trail is just a list of the audit hashes
    # The pattern trail tracks the ordering
    zipped = Enum.zip(audit_trail, pattern_trail)

    # Create the audit path with the hash order information already encoded into the path
    # (This way we don't have to keep track of left and rights separately or use extra overhead structures)
    # The path is a nested tuple :)
    Enum.reduce(zipped, {}, fn {audit_hash, directive}, acc ->
      case directive do
        :audit_on_right -> {acc, audit_hash}
        :audit_on_left -> {audit_hash, acc}
      end
    end)
  end

  defp traverse(%Node{search_key: s_key, left: l, right: r}, key, audit_trail, pattern_trail)
       when is_binary(key) and is_list(audit_trail) and is_list(pattern_trail) and not is_nil(l) and
              not is_nil(r) do
    # At each tree level we generate:
    # 1) the next audit pattern order, 
    # 2) the next audit hash,
    # 3) and the next node level to traverse to

    # true means the path is on the left and the audit hash is the right sibling hash
    # so when we verify, we do hash(hash_acc, audit_hash)

    # false means the path is on the right and the audit hash is the left sibling
    # so when we verify, instead of hash(hash_acc, audit_hash) we do hash(audit_hash, hash_acc)

    {next_pattern, next_audit, next_node} =
      case key <= s_key do
        true -> {:audit_on_right, r.key_hash, l}
        false -> {:audit_on_left, l.key_hash, r}
      end

    # By putting the accumulated states within the function as params, we are tail recursive
    traverse(next_node, key, [next_audit] ++ audit_trail, [next_pattern] ++ pattern_trail)
  end

  # We use pattern matching to descend through our audit path tuple, 
  # we keep track of the audit path via a stack,
  # Eventually we reduce the stack to the accumulated hash value
  @spec prove(Tree.key(), tuple, list) :: String.t()
  defp prove(key, {acc, r}, stack) when is_binary(r) and is_tuple(acc) do
    prove(key, acc, [{r, :audit_on_right}] ++ stack)
  end

  defp prove(key, {l, acc}, stack) when is_binary(l) and is_tuple(acc) do
    prove(key, acc, [{l, :audit_on_left}] ++ stack)
  end

  defp prove(key, {}, stack) when is_binary(key) and is_list(stack) do
    key_hash = hash(key)

    # We verify the key from bottom up (leaves)
    # Hence the stack is prepended to, allowing us to start at the leaf level

    Enum.reduce(stack, key_hash, fn {audit_hash, directive}, hash_acc ->
      case directive do
        :audit_on_left -> hash_concat(audit_hash, hash_acc)
        :audit_on_right -> hash_concat(hash_acc, audit_hash)
      end
    end)
  end
end
