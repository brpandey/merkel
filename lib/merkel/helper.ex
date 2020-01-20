defmodule Merkel.Helper do
  @moduledoc """
  Module assists in tree creation
  """

  @type key :: Merkel.BinaryHashTree.key()
  @type pair :: Merkel.BinaryHashTree.pair()

  import Merkel.Crypto
  alias Merkel.BinaryNode, as: Node

  @doc """
  Public helper to create the tree with an option to specify and vary
  the heavier tree side when we don't have an equal number of nodes :)
  """
  @spec create_tree(list(pair), tuple) :: tuple
  def create_tree([{k, _v} | _tail] = list, toggle_acc \\ {false, false})
      when is_binary(k) do
    # Sort the list by the 0th element of each tuple -> the key
    list = List.keysort(list, 0)

    size = Enum.count(list)

    # Once finished the sorted list is reduced into a tree
    # signified by the tree root, with an empty consume list
    {{root, _kacc}, [], _} = partition_build(list, size, toggle_acc)

    {size, root}
  end


  ##############################################################################
  # Tree creation helpers

  # Helpers to create a balanced tree from a list of sorted k-v pairs using partitioning
  # Used on setup

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

  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

  # Divide number into its whole rough halves e.g. for 5 its 3 and 2
  # By default, the left subtree is the dominant side as it gets the larger number 
  # (making it deeper)

  # We override this by specifying which side we want the bigger number to be
  # and if we want that to alternate or not if the halves differ in size

  #             5                    5
  #            / \                  / \
  #           3   2                2   3
  #          / \ / \              / \ / \
  #         2  1 1  1            1  1 1  2
  #        / \                          / \
  #       1   1                        1   1
  #
  # The figure on the left is 0 0 , and the right is 1 0

  @spec partition(non_neg_integer, tuple) :: {non_neg_integer, non_neg_integer, tuple}
  defp partition(n, {on_right, alternate} = toggle_acc)
       when is_integer(n) and is_boolean(on_right) and is_boolean(alternate) do
    # smaller and bigger half when n is odd, otherwise both halves are equal
    {sh, bh} = do_partition(n)

    case sh != bh do
      # we only toggle if the halves are different sizes
      true ->
        cond do
          # Given the two choices we generate the four possible match cases
          # a) 1 1 b) 1 0 c) 0 1 d) 0 0 
          # Note we don't change alternate 
          # We just toggle on_right depending on alternate
          on_right && alternate ->
            {sh, bh, {not on_right, alternate}}

          on_right && not alternate ->
            {sh, bh, {on_right, alternate}}

          not on_right && alternate ->
            {bh, sh, {not on_right, alternate}}

          not on_right && not alternate ->
            {bh, sh, {on_right, alternate}}
        end

      false ->
        {sh, bh, toggle_acc}
    end
  end

  # Divide number into its whole rough halves e.g. for 5 its 3 and 2
  # Given the toggle stream passed in, we ask it where the larger numbered
  # subtree goes, to the left or to the right?

  # Doing this randomly for larger trees creates diverse patterns

  @spec partition(non_neg_integer, Enumerable.t()) :: {non_neg_integer, non_neg_integer, tuple}
  defp partition(n, toggle_acc) when is_integer(n) and not is_nil(toggle_acc) do
    {sh, bh} = do_partition(n)

    case sh != bh do
      # we only toggle if the halves are different sizes
      true ->
        case Enum.take(toggle_acc, 1) |> List.first() do
          true -> {sh, bh, toggle_acc}
          false -> {bh, sh, toggle_acc}
        end

      false ->
        {sh, bh, toggle_acc}
    end
  end

  # Given a number n, it is returned into its halves: the smaller and larger half if odd
  defp do_partition(n) when n > 1, do: {Kernel.div(n, 2), n - Kernel.div(n, 2)}

  @spec partition_build(list(pair), non_neg_integer, tuple | Enumerable.t()) :: tuple

  # Leaves case
  # From the diagram above the 1's are where the leaves go
  defp partition_build([head | tail], 1, t_acc) when is_tuple(head) do
    {leaf_level(head), tail, t_acc}
  end

  # Inner nodes case (all the inner nodes are values that are > 1)
  defp partition_build(list, size, toggle_acc)
       when size > 1 and is_list(list) and is_tuple(hd(list)) do
    # Divide the size into its integer rough halves e.g. for 5 its 3 and 2
    {n1, n2, t_acc} = partition(size, toggle_acc)

    # Since it's postorder do left, then right followed by inner
    {{left, l_acc}, list, t_acc} = partition_build(list, n1, t_acc)
    {{right, r_acc}, list, t_acc} = partition_build(list, n2, t_acc)

    inner = inner_level(left, right, {l_acc, r_acc})

    {inner, list, t_acc}
  end

  ##############################################################################
  # Node creation helpers  

  # Create leaf node
  @spec leaf(pair) :: Node.t()
  def leaf({k, v}) when is_binary(k) do
    %Node{key_hash: hash(k), search_key: k, key: k, value: v, height: 0}
  end

  # Create inner node
  @spec inner(Node.t(), Node.t(), key) :: Node.t()
  def inner(%Node{} = l, %Node{} = r, s_key) when is_binary(s_key) do
    %Node{
      key_hash: hash_concat(l, r),
      search_key: s_key,
      height: Kernel.max(l.height, r.height) + 1,
      left: l,
      right: r
    }
  end

  @spec leaf_level(pair) :: {Node.t(), key}
  defp leaf_level({k, v}) when is_binary(k) do
    # Along with the node we pass the largest key from the left subtree 
    # (since it's nil we use the key)
    {leaf({k, v}), k}
  end

  # Create inner node using level order create
  @spec inner_level(Node.t(), Node.t(), tuple) :: tuple
  defp inner_level(%Node{} = l, %Node{} = r, {l_lkey, r_lkey} = _largest_acc) do
    # we use the largest key from the left subtree as the search key
    node = inner(l, r, l_lkey)
    # we pass on the largest key from the right subtree to be used as a search key
    # for an inner node at a higher level
    {node, r_lkey}
  end
end
