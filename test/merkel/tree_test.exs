defmodule Merkel.TreeTest do
  use ExUnit.Case, async: true

  # Test tree create, lookup, keys, insert, delete, size, tree_hash operations

  require Logger
  import Merkel.Helper
  import Merkel.Crypto

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node

  @list [{"zebra", 23}, {<<9,9,2>>, "992"}, {"giraffe", nil}, {"anteater", "12"}, 
         {"walrus", 49}, {<<23,1,0>>, 99}, {<<100,2>>, :furry}, {"lion", "3"}, 
         {"kangaroo", nil}, {"cow", 99}, {"leopard", :fast}]

  # Would like to use quick check or some property testing
  # But will do it the old fashioned way to build intuition first
  # Plus its fun drawing


  # Run before all tests
  setup_all do

    # seed random number generator with random seed
    << a :: 32, b :: 32, c :: 32 >> = :crypto.strong_rand_bytes(12)
    r_seed = {a, b, c}
        
    _ = :rand.seed(:exsplus, r_seed)

    :ok
  end


  # nil

  test "empty tree" do
    
    pair = {k0, _v} = {"starfish", :blue}
    
    empty = Merkel.new()
    assert %Tree{size: 0, root: nil} == empty
    
    # lookup item
    assert {:error, "key: starfish not found in tree"} == Merkel.lookup(empty, k0)
    
    # get keys list
    assert [] == Merkel.keys(empty)

    root_hash = "3755b417b0f937026ac1b867a397d6dec80dfd463c232c2daaf1de974b93da82"

    assert root_hash == Merkel.Crypto.hash(k0)

    # insert item
    root = %Node{key_hash: root_hash, search_key: k0, key: k0, value: :blue, height: 0, left: nil, right: nil}
    tree = %Tree{size: 1, root: root} 

    assert tree == Merkel.insert(empty, pair)
    
    # delete item
    assert {:error, "key: starfish not found in tree"} == Merkel.delete(empty, k0)
    
    # size
    assert 0 == Merkel.size(empty)
    
    # root hash
    assert nil == Merkel.tree_hash(empty)
    
  end


  # root

  describe "tree of size 1" do
    setup :build_tree

    @tag size: 1
    test "crud", %{size: _sz, trees: {t0, t1, t2}, valid_keys: vkeys, invalid_keys: ikeys, valid_values: vvs} do

      assert t0 == t1
      assert t1 == t2

      pair = {k2, v2} = {"starfish", :blue}

      "zebra" = k1 = Enum.at(vkeys, 0)
      v1 = Enum.at(vvs, 0)
      ik = Enum.at(ikeys, 0)

      k1_hash = "676cb75018edccf10fce6f376f2124e02c3293fa3fe8f953c75386198c714514"
      assert k1_hash == hash(k1)

      root = %Node{key_hash: k1_hash, search_key: k1, key: k1, value: v1, height: 0, left: nil, right: nil}
      tree = %Tree{size: 1, root: root} 

      assert tree == t0
    
      # lookup item
      assert {:ok, ^v1} = Merkel.lookup(t0, k1)
      assert {:error, _} = Merkel.lookup(t0, ik)
      
      # get keys list
      assert vkeys == Merkel.keys(t0)

      # zebra is greater than starfish so put it on the right
      k2_hash = hash(k2)
      root_hash = hash_concat(k2_hash, k1_hash)
      
      # insert item but don't save merkel tree
      k1_node = %Node{key_hash: k1_hash, search_key: k1, key: k1, value: v1, height: 0, left: nil, right: nil}
      k2_node = %Node{key_hash: k2_hash, search_key: k2, key: k2, value: v2, height: 0, left: nil, right: nil}
      root = %Node{key_hash: root_hash, search_key: k2, key: nil, value: nil, height: 1, left: k2_node, right: k1_node}
      tree = %Tree{size: 2, root: root} 
      
      assert tree == Merkel.insert(t0, pair)
      
      d_tree = %Tree{size: 0, root: nil}

      # delete item
      assert {:error, _} = Merkel.delete(t0, ik)
      assert {:ok, d_tree} == Merkel.delete(t0, k1)
      
      # size
      assert 1 == Merkel.size(t0)
      
      # root hash
      assert ^k1_hash = Merkel.tree_hash(t0)
      
    end
    
    @tag size: 1
    test "authentication", %{trees: {t0, _, _}, valid_keys: vk, invalid_keys: ik} do

      Logger.debug("authentication: tree is #{inspect t0}, valid keys is #{vk}, invalid_keys is #{ik}")

    end


  end

  # root 
  #  / \
  # l   r

  describe "tree of size 2" do

  end

  # 1) false, _               2) true, _             
  #       root                 root
  #      /    \               /    \
  #  inner     r             l      inner
  #  / \                            /    \
  # l   r                          l      r

  describe "tree of size 3" do


  end

  #        root
  #       /     \
  #  inner       inner
  #  /    \      /    \
  # l     r     l      r

  describe "tree of size 4" do

  end

  # 1) false, false
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #   inner   r  l       r
  #   /   \
  #  l     r

  # 2) false, true
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #    l    inner l       r
  #         /   \
  #        l     r

  # 3) true, false
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #    l      r  l      inner
  #                     /   \
  #                    l     r

  # 4) true, true
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #    l      r inner    r
  #             /   \
  #            l     r

  describe "tree of size 5" do

  end

#  defp build_tree(context) do
  defp build_tree(%{size: size}) when size > 0 do

    ls = Enum.count(@list)
    
    pairs = Enum.take(@list, size)
    valid_keys = Enum.take(@list, size) |> Enum.map(fn {k,_v} -> k end)
    invalid_keys = Enum.take(@list, size - ls) |> Enum.map(fn {k, _v} -> k end)
    valid_values = Enum.take(@list, size) |> Enum.map(fn {_k,v} -> v end)
    
    # These three trees don't need to be the same structure but should have the same contents

    {^size, r0} = create_tree(pairs) # This tree creates the default tree with the larger subtree always on the left
    {^size, r1} = create_toggle_tree(pairs) # The tree creates a balanced tree but in a random pattern
    t2 = Enum.reduce(pairs, Merkel.new(), 
                     fn {k,v}, acc -> # This tree is iteratively constructed and uses rotations
                          Merkel.insert(acc, {k,v})
                     end)
    
    t0 = %Tree{size: size, root: r0}
    t1 = %Tree{size: size, root: r1}

    [size: size, trees: {t0, t1, t2}, valid_keys: valid_keys, invalid_keys: invalid_keys, valid_values: valid_values]
  end


end
