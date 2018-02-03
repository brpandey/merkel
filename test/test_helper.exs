ExUnit.start()

defmodule Merkel.TestHelper do
  @moduledoc "Helper routines to make test state easier to setup / run"

  import Merkel.Helper
  alias Merkel.BinaryHashTree, as: Tree

  # size 20
  @list [
    {"zebra", 23},
    {<<9, 9, 2>>, "992"},
    {"giraffe", nil},
    {"anteater", "12"},
    {"walrus", 49},
    {<<23, 1, 0>>, 99},
    {<<100, 2, 99>>, :furry},
    {"lion", "3"},
    {"kangaroo", nil},
    {"cow", 99},
    {"leopard", :fast},
    {<<3, 2, 1>>, nil},
    {"kingfisher", :greedy},
    {"turtle", "shell"},
    {"lynx", 10},
    {<<8>>, ""},
    {<<76, 65, 11, 10, 9, 82>>, :new},
    {"hippo", 10},
    {"elephant", "gray"},
    {"aardvark", 7}
  ]

  @list2_size 65

  @list2 [
    {"alligator", nil},
    {"ant", nil},
    {"bear", nil},
    {"bee", nil},
    {"bird", nil},
    {"camel", nil},
    {"cat", nil},
    {"cheetah", nil},
    {"chicken", nil},
    {"chimpanzee", nil},
    {"cow", nil},
    {"crocodile", nil},
    {"deer", nil},
    {"dog", nil},
    {"dolphin", nil},
    {"duck", nil},
    {"eagle", nil},
    {"elephant", nil},
    {"emu", nil},
    {"fish", nil},
    {"fly", nil},
    {"fox", nil},
    {"frog", nil},
    {"giraffe", nil},
    {"goat", nil},
    {"goose", nil},
    {"goldfish", nil},
    {"hamster", nil},
    {"hawk", nil},
    {"heron", nil},
    {"hippopotamus", nil},
    {"horse", nil},
    {"hummingbird", nil},
    {"kangaroo", nil},
    {"kitten", nil},
    {"kiwi", nil},
    {"lion", nil},
    {"lobster", nil},
    {"lynx", nil},
    {"monkey", nil},
    {"octopus", nil},
    {"owl", nil},
    {"panda", nil},
    {"peacock", nil},
    {"pheasant", nil},
    {"pig", nil},
    {"puppy", nil},
    {"rabbit", nil},
    {"rat", nil},
    {"salamander", nil},
    {"scorpion", nil},
    {"seal", nil},
    {"shark", nil},
    {"sheep", nil},
    {"snail", nil},
    {"snake", nil},
    {"spider", nil},
    {"squirrel", nil},
    {"stork", nil},
    {"tiger", nil},
    {"turkey", nil},
    {"turtle", nil},
    {"vulture", nil},
    {"wolf", nil},
    {"zebra", nil}
  ]

  # Routines to construct the tree of desired size, with three tree types
  # The three tree types are merely to provide some diversity in tree formation 
  # since we are implementing a dynamic tree library with rotations

  # Along with the trees we provide a convenience list of relevant tree data

  def build_tree(size) when is_integer(size), do: build_tree(%{size: size})

  def build_tree(%{size: size}, list \\ @list) when size > 0 do
    list = Enum.shuffle(list)

    pairs = Enum.take(list, size)
    valid_keys = Enum.take(list, size) |> Enum.map(fn {k, _v} -> k end)
    invalid_keys = Enum.take(list, size - Enum.count(list)) |> Enum.map(fn {k, _v} -> k end)
    valid_values = Enum.take(list, size) |> Enum.map(fn {_k, v} -> v end)

    # These three trees don't need to be the same structure but should have the same contents

    # This tree creates the default tree with the larger subtree always on the left
    t0 = Merkel.new(pairs)
    # The tree creates a balanced tree but in a random pattern
    {^size, r1} = create_toggle_tree(pairs)
    t1 = %Tree{size: size, root: r1}

    t2 =
      Enum.reduce(
        pairs,
        Merkel.new(),
        # This tree is iteratively constructed and uses rotations
        fn {k, v}, acc ->
          Merkel.insert(acc, {k, v})
        end
      )

    [
      size: size,
      trees: {t0, t1, t2},
      valid_keys: valid_keys,
      invalid_keys: invalid_keys,
      valid_values: valid_values
    ]
  end

  def big_tree(), do: build_tree(%{size: @list2_size}, @list2)
end
