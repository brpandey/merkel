defmodule Merkel.TreeHelperTest do
  use ExUnit.Case, async: true

  # Test tree helpers

  require Logger

  import Merkel.Helper

  @list1 [
    {"zebra", 23},
    {<<9, 9, 2>>, "992"},
    {"giraffe", nil},
    {"anteater", "12"},
    {"walrus", 49}
  ]

  @list2 [
    {"leopard", :fast},
    {<<3, 2, 1, 12, 10>>, nil},
    {"kingfisher", :greedy},
    {"turtle", "shell"},
    {"lynx", 10},
    {<<8>>, ""},
    {<<76, 9, 1, 1>>, :new},
    {"hippo", 10},
    {"elephant", "gray"},
    {"aardvark", 7},
    {"eagle", <<8>>},
    {"leopold", :slow},
    {<<3, 2, 1, 12>>, false},
    {"king", :bird},
    {"turtlewax", "goop"},
    {"links", 10_000_000},
    {<<88>>, nil},
    {<<66, 1>>, :old},
    {"ankle", 100}
  ]

  # Would like to use quick check or some property testing
  # But will do it the old fashioned way to build intuition first
  # Plus its fun drawing

  # Run before all tests
  setup_all do
    # seed random number generator with random seed
    <<a::32, b::32, c::32>> = :crypto.strong_rand_bytes(12)
    r_seed = {a, b, c}

    _ = :rand.seed(:exsplus, r_seed)

    :ok
  end

  test "4 different trees with different alternating patterns of size 5" do
    # 0 0   on_right alt
    {_size, root0} = create_tree(@list1, {false, false})
    # 0 1   on_right alt
    {_size, root1} = create_tree(@list1, {false, true})
    # 1 0   on_right alt
    {_size, root2} = create_tree(@list1, {true, false})
    # 1 1   on_right alt
    {_size, root3} = create_tree(@list1, {true, true})

    assert root0 != root1
    assert root0 != root2
    assert root0 != root3
    assert root1 != root2
    assert root1 != root3
    assert root2 != root3
  end

  test "2 different toggle trees of size 19" do
    {_size, root0} = create_toggle_tree(@list2)
    {_size, root1} = create_toggle_tree(@list2)

    assert root0 != root1
  end
end
