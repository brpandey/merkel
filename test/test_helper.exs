ExUnit.start()

defmodule Merkel.TestHelper do
  @moduledoc "Helper routines to make test state easier to setup / run"

  # Since this is not in the lib directory we have to explicitly load it
  Code.load_file("test/test_data_helper.exs")

  alias Merkel.Helper
  alias Merkel.TestDataHelper, as: TDHelper
  alias Merkel.BinaryHashTree, as: Tree

  # Keep the actual test data in a separate file
  @list1 TDHelper.list1()
  @list2 TDHelper.list2()
  @list2_size TDHelper.list2_size()
  @tree_str_64 TDHelper.tree_str_64()

  # Routines to construct the tree of desired size given a static list
  # The three tree types available are merely to provide some diversity in tree formation 
  # since we are implementing a dynamic tree library with rotations

  # Along with the trees we provide a convenience list of relevant tree data

  def build_tree(size) when is_integer(size), do: build_tree(%{size: size})

  def build_tree(%{size: size}, list \\ @list1) when size > 0 do
    list = Enum.shuffle(list)

    pairs = Enum.take(list, size)
    valid_keys = Enum.take(list, size) |> Enum.map(fn {k, _v} -> k end)
    invalid_keys = Enum.take(list, size - Enum.count(list)) |> Enum.map(fn {k, _v} -> k end)
    valid_values = Enum.take(list, size) |> Enum.map(fn {_k, v} -> v end)

    # These three trees don't need to be the same structure but should have the same contents

    # This tree creates the default tree with the larger subtree always on the left
    t0 = Tree.create(pairs)
    # The tree creates a balanced tree but in a random pattern

    {^size, r1} = create_toggle_tree(pairs)
    t1 = %Tree{size: size, root: r1}
    t2 = create_tree_iteratively(pairs)

    [
      size: size,
      trees: {t0, t1, t2},
      valid_keys: valid_keys,
      invalid_keys: invalid_keys,
      valid_values: valid_values
    ]
  end

  def big_tree(), do: build_tree(%{size: @list2_size}, @list2)
  def big_tree(size) when size > 0, do: build_tree(%{size: size}, @list2)

  def create_helper({size, root}) do
    %Tree{size: size, root: root}
  end

  def create_tree_iteratively(list) when is_list(list) and is_tuple(hd(list)) do
    Enum.reduce(
      list,
      Tree.create(),
      # This tree is iteratively constructed and uses rotations
      fn {k, v}, acc ->
        Tree.insert(acc, {k, v})
      end
    )
  end

  
  # Test helper to create the a balanced tree but with inner node branches alternating
  # in random ways.  Specifically if an inner node has a subtree with 3 children and another
  # subtree with 2 children, it is randomly determined if the left child will get the subtree
  # of 3 children and vice versa.  Point being it is not set that the left child will always get
  # the larger subtree.

  def create_toggle_tree([{k, _v} | _tail] = list)
  when is_binary(k) do

    # Streams are composable so each of these functions will be applied to each 
    # value retrieved from the stream

    # Returns a stream of boolean toggle values
    toggle_stream =
      Stream.repeatedly(&:rand.uniform/0)
      |> Stream.map(fn x -> x * 2 end)
      |> Stream.map(fn x -> x >= 1 end)

    Helper.create_tree(list, toggle_stream)
  end


  def tree_str_64(), do: @tree_str_64

end
