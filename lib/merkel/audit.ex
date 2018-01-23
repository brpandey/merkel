defmodule Merkel.Proof.Audit do

  alias Merkel.Proof.Audit

  alias Merkel.BinaryHashTree, as: BHTree
  alias Merkel.BinaryNode, as: BNode

  require Logger

  @base_2 2

  defstruct key: nil, index: -1, path: []

  # Create audit proof
  # This includes the set of sibling hashes in the path to the merkle root, 
  # that will ensure verification

  # Either create the audit proof with the hash or with the original string data

  def create(%BHTree{} = tree, {:data, str}) when is_binary(str) do
    create(tree, {:hash, BHTree.hash(str)})
  end


  def create(%BHTree{root: %BNode{} = root} = tree, {:hash, hash})
  when is_binary(hash) and not(is_nil(root)) do

    index = Map.get(tree.index, hash) # Retrieve the index value

    if index == nil, do: raise "Index value not found"

    path = traverse(tree.root, index, [])
    
    %Audit{key: hash, index: index, path: path}
  end


  def verify(%Audit{key: key_hash, index: index, path: trail}, tree_hash)
  when is_binary(key_hash) and is_list(trail) and is_integer(index)
  and is_binary(hd(trail)) and is_binary(tree_hash) do

    
    # Basically we walk through the list of audit hashes (trail) which represent
    # a distinct tree level

    # We start of with the height at the next higher level, e.g. the parent level
    # of the key_hash and first sibling audit hash, which is 1.

    # From there we keep pushing up to the next level

    # We check to make sure how we should concatenate the hashes properly based on,
    # for each level, if the audit hash sibling is to the left or right of the path sibling
    # if the path sibling is on the left, then we hash like hash(path <> audit)
    # if the path sibling is on the right, then we hash like hash(audit <> path)

    {acc_hash, _} = 
      Enum.reduce(
        trail, {key_hash, 1}, fn audit_hash, {hash_acc, height_acc} ->

          Logger.info("hash_acc is #{hash_acc}, audit_hash is #{audit_hash}")

          # true means the path is on the right and the audit hash is the left sibling
          # so instead of hash(hash_acc, audit_hash) we do hash(audit_hash, hash_acc)

          flip = path_direction(index, height_acc)

          hash_acc = hash_by_order(hash_acc, audit_hash, flip)
          {hash_acc, height_acc + 1}
        end)
    
    Logger.info("acc_hash is #{acc_hash}, tree_hash is #{tree_hash}")

    acc_hash == tree_hash
  end


  #####################
  # Private functions #
  #####################


  # Recursive traverse implementation which builds the audit hash verification trail
  # These are the sibling node hashes along the way from the leaf in question to the
  # merkle tree root.

  # We start from the root, so the trail is purposely composed backwards

  defp traverse(%BNode{height: 0}, _index, audit_trail), do: audit_trail
  defp traverse(%BNode{} = inner, index, audit_trail) when is_integer(index) and is_list(audit_trail) do


    Logger.info("traverse 1 is inner: #{inspect inner}, index: #{inspect index}, audit_trail: #{audit_trail}")
    
    # At each tree level we call path_next to get the next audit hash,
    # and the next node level to traverse to

    {next_audit_hash, next_node} = path_next(inner, index)

    Logger.info("traverse 2 is next_audit_hash: #{next_audit_hash}, next_node: #{inspect next_node}")

    # (To verify the hashes, it needs to be done from the bottom up, 
    # so prepending to the list of hashes puts them in correct order)

    traverse(next_node, index, [next_audit_hash] ++ audit_trail)
  end


  # Given the current level, returns where the audit node lies (l,r) 
  # and the direction to traverse lies (l,r) - these are mutually exclusive

  # The audit path are the sibling nodes on the path from the leaf to the root

  defp path_next(%BNode{height: height, left: l, right: r}, index)
  when is_integer(height) and is_integer(index) and not(is_nil(l)) and not(is_nil(r)) do

    # If the key lies on the right subtree, the audit hash is on the left sibling node
    # Else if the key lies on the left subtree, the audit hash is on the right sibling node

    {_audit_sibling_hash, _traverse_next_node} =
      case path_direction(index, height) do
        true -> {l.value, r} 
        false -> {r.value, l}
      end

  end


  # Returns 0 if the path is to the left or 1 if the path is to the right
  defp path_direction(index, height) when is_integer(index) and is_integer(height) do

    # From the perspective of the node at height "height", is the index in its right (1) subtree
    # or left (0) subtree?

    # Since this is a binary tree we can figure out where the leaf lies, given
    # the current height of the tree and its index.  We assume the indices start from 
    # 0 on the bottom left leaf of the tree

    x = :math.pow(@base_2, height) |> round
    rem(index, x) >= div(x, 2)
  end


  defp hash_by_order(x, y, flip)
  when is_binary(x) and is_binary(y) and is_boolean(flip) do
    case flip do
      true -> BHTree.hash(y <> x) # if true flip
      false -> BHTree.hash(x <> y)
    end
  end
  

end
