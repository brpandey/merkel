defmodule Merkel.AVL do
  @moduledoc """
  Implements the AVL balance rotations for a binary tree
  A self-balancing AVL tree ensures the tree height is always O(log n)
  """

  alias Merkel.BinaryNode, as: Node

  @type skey :: Merkel.BinaryHashTree.key()

  ##############################################################################
  # AVL balance and rotation helpers

  @doc "Checks whether the tree rooted at node n needs to be balanced"
  @spec balance?(Node.t()) :: boolean
  def balance?(%Node{} = n), do: n |> height_delta |> Kernel.abs() > 1

  @doc """
  Balances tree rooted at node n using avl rotations.
  Runs the update callback function for each node that is affected by rotations
  """
  @spec balance(Node.t(), skey, function) :: Node.t()
  def balance(%Node{} = node, s_key, nil), do: balance(node, s_key, & &1)

  def balance(%Node{left: l, right: r} = node, search_key, fn_update)
      when is_binary(search_key) do
    # Using height delta we determine if we need to balance the tree at this node
    delta = height_delta(node)

    # 4 cases to handle a node imbalance

    _node =
      cond do
        # These are the 4 Cases

        # 1) y is left child of z and x is left child of y (Left Left Case)
        # 2) y is right child of z and x is right child of y (Right Right Case)
        # 3) y is left child of z and x is right child of y (Left Right Case)
        # 4) y is right child of z and x is left child of y (Right Left Case)

        # Case 1, Left Left

        # Since the delta is greater than 1, z's left subtree is higher
        # and since search_key is less than y's search_key it was inserted on its left
        # Hence - left left

        #         z                                      y 
        #        / \                                   /   \
        #       y   T4      Right Rotate (z)          x      z
        #      / \          - - - - - - - - ->      /  \    /  \ 
        #     x   T3                               T1  T2  T3  T4
        #    / \
        #  T1   T2

        delta > 1 and l != nil and search_key <= l.search_key ->
          right_rotate(node, fn_update)

        # Case 2, Right Right

        # Since the delta is less than -1, z's right subtree is higher
        # and since the search_key is greater than y's search_key 
        # it was inserted on the right
        # Hence - right right

        #    z                                y
        #   /  \                            /   \ 
        #  T1   y     Left Rotate(z)       z      x
        #      /  \   - - - - - - - ->    / \    / \
        #     T2   x                     T1  T2 T3  T4
        #         / \
        #       T3  T4

        delta < -1 and r != nil and search_key > r.search_key ->
          left_rotate(node, fn_update)

        # Case 3, Left Right

        # Since the delta is greater than 1, z's left subtree is higher
        # Since the search_key is greater than y's search key, the node
        # was inserted on y's right subtree
        # Hence - left right

        #      z                               z                           x
        #     / \                            /   \                        /  \ 
        #    y   T4  Left Rotate (y)        x    T4  Right Rotate(z)    y      z
        #   / \      - - - - - - - - ->    /  \      - - - - - - - ->  / \    / \
        # T1   x                          y    T3                    T1  T2 T3  T4
        #     / \                        / \
        #   T2   T3                    T1   T2

        delta > 1 and l != nil and search_key > l.search_key ->
          %Node{node | left: left_rotate(l, fn_update)} |> right_rotate(fn_update)

        # Case 4, Right Left

        # Since the delta is less than -1, z's right subtree is higher
        # Since the search_key is less than y's search key, the node
        # was inserted on y's left subtree
        # Hence - right left

        #    z                            z                            x
        #   / \                          / \                          /  \ 
        # T1   y   Right Rotate (y)    T1   x      Left Rotate(z)   z      y
        #     / \  - - - - - - - - ->     /  \   - - - - - - - ->  / \    / \
        #    x   T4                      T2   y                  T1  T2  T3  T4
        #   / \                              /  \
        # T2   T3                           T3   T4

        delta < -1 and r != nil and search_key <= r.search_key ->
          %Node{node | right: right_rotate(r, fn_update)} |> left_rotate(fn_update)

        # Default case
        true ->
          node
      end
  end

  _ = """
  Right rotate subtree rooted at z. See following diagram
  We rotate z (the old root) to the right leaving y as the new root
  T1, T2, T3 and T4 are subtrees.
         z                                      y 
        / \                                   /   \
       y   T4      Right Rotate (z)          x      z
      / \          - - - - - - - - ->      /  \    /  \ 
     x   T3                               T1  T2  T3  T4
    / \
  T1   T2
  """

  @spec right_rotate(Node.t(), function) :: Node.t()
  defp right_rotate(%Node{left: %Node{left: x, right: t3} = y, right: t4} = z, fn_update) do
    # Perform rotation, update heights and max interval
    z = fn_update.(%Node{z | left: t3, height: max_height(t3, t4) + 1})
    _y = fn_update.(%Node{y | right: z, height: max_height(x, z) + 1})
  end

  _ = """
  Left rotate subtree rooted at z. See following diagram
  We rotate z (the old root) to the left leaving y as the new root
    z                                y
   /  \                            /   \ 
  T1   y     Left Rotate(z)       z      x
      /  \   - - - - - - - ->    / \    / \
     T2   x                     T1  T2 T3  T4
         / \
       T3  T4
  """

  @spec left_rotate(Node.t(), function) :: Node.t()
  defp left_rotate(%Node{left: t1, right: %Node{left: t2, right: x} = y} = z, fn_update) do
    # Perform rotation, update heights and max interval
    z = fn_update.(%Node{z | right: t2, height: max_height(t1, t2) + 1})
    _y = fn_update.(%Node{y | left: z, height: max_height(z, x) + 1})
  end

  # Height helpers

  # Update max tree height
  @spec max_height(Node.t() | nil, Node.t() | nil) :: non_neg_integer
  defp max_height(left, right) do
    Kernel.max(do_height(left), do_height(right))
  end

  @spec height_delta(Node.t() | nil) :: non_neg_integer
  defp height_delta(nil), do: 0
  defp height_delta(%Node{left: l, right: r}), do: do_height(l) - do_height(r)

  @spec do_height(Node.t() | nil) :: non_neg_integer
  defp do_height(nil), do: 0
  defp do_height(%Node{height: height}), do: height
end
