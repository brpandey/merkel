defmodule Merkel.Printer do
  @moduledoc """
  Module implements pretty printing of merkle binary hash tree
  """

  alias Merkel.BinaryNode, as: Node
  alias Merkel.BinaryHashTree, as: Tree

  @level_delta 7

  @doc """
  Prints the merkle binary hash tree rotated to the left 90 degrees so that
  large trees will fit in the console window

  # We perform a "reverse inorder search" and display the tree rotated left

  # Inorder is typical left-node-right, but in this case we are doing right-node-left
  # The rightmost on the first line, all the way down to the leftmost which is one the last line

  # So given tree:    R           This will be printed as:     4
  #                  / \                                     
  #                 3   4                                   R
  #                                                          
  #                                                            3

  # Base case if root is nil, stop recursing and return back
  # The closer we are to the leaves, indent is higher, the closer to the root index is smaller

  """
  @spec pretty_print(Tree.t()) :: :ok
  def pretty_print(%Tree{root: nil}), do: :ok

  def pretty_print(%Tree{root: root}) do
    # Create a new line before we print tree out
    IO.puts("")
    do_pretty(root, 0)
  end

  # Recursive private helper functions

  @spec do_pretty(nil | Node.t(), non_neg_integer) :: :ok
  defp do_pretty(nil, _indent), do: :ok

  # Case: Leaf node, print the height, key, and abbrev hash
  defp do_pretty(%Node{height: h, key: k, key_hash: kh, left: nil, right: nil}, indent)
       when is_binary(k) and is_binary(kh) do
    hkey = Node.trunc_hash_key(kh)
    IO.puts("#{String.duplicate(" ", indent)}#{h} #{k} #{hkey}..")
  end

  # Case: Inner node, print the height, search key, and (abbrev) hash
  defp do_pretty(%Node{height: h, search_key: sk, key_hash: hash, left: l, right: r}, indent)
       when not is_nil(l) and not is_nil(r) and indent >= 0 and is_binary(sk) and is_binary(hash) do
    # Go right
    do_pretty(r, indent + @level_delta)

    # Print current node's search key
    skey = Node.trunc_search_key(sk)
    hkey = Node.trunc_hash_key(hash)

    # Print right branch
    IO.puts("#{String.duplicate(" ", indent + div(@level_delta, 2))}/")

    # If the current node is root, include its hash in full
    case indent do
      # Root
      0 ->
        IO.puts("\n#{String.duplicate(" ", indent)}#{h} #{skey} #{hash} (Merkle Root)\n")

      # Inner node
      _ ->
        IO.puts("#{String.duplicate(" ", indent)}#{h} #{skey} #{hkey}..")
    end

    # Print left branch
    IO.puts("#{String.duplicate(" ", indent + div(@level_delta, 2))}\\")

    # Go left
    do_pretty(l, indent + @level_delta)
  end
end
