defmodule Merkel.TreePropTest do
  @moduledoc """
  Property testing using PropCheck (PropEr)
  See README for exploring property testing interactively in iex
  """

  use ExUnit.Case
  use PropCheck
  require Logger

  alias Merkel.Helper
  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.Audit, as: Audit
  alias Merkel.TreePropTest, as: Mod

  import Merkel.TestHelper

  @min_tree_size :option_min_one_tree
  @middle_key_min_tree_size :option_min_four_tree


  property "verify bulk data retrieval routines (keys, values, to_list) work in tree of variable sizes" do
    forall {t, pairs, sorted_keys, _key, _size} <- generate_tree() do

      # Tree.keys already sorted
      assert sorted_keys == Tree.keys(t)

      the_values = Tree.values(t) |> Enum.sort()
      sorted_values = pairs |> values() |> Enum.sort()
      assert sorted_values == the_values

      # Tree.to_list already sorted
      sorted_list = pairs |> Enum.sort()
      assert sorted_list == Tree.to_list(t)
    end
  end

  property "verify audit hashes work for each key in tree of variable sizes" do
    forall {t, _pairs, _sorted_keys, key, _size} <- generate_tree() do
      proof = Audit.create(t, key)
      tree_hash = Tree.tree_hash(t)

      _is_verified = Audit.verify(proof, tree_hash)
    end
  end

  property "verify tree using audit proof path" do
    forall {t, _pairs, _all_keys, key, size} <- generate_tree() do
      proof = Audit.create(t, key)
      length = Audit.length(proof)
      balanced_height = round(:math.log2(size))
      is_balanced = abs(length - balanced_height) <= 2

      if !is_balanced do
        Logger.debug("Prop1, not balanced - key is #{key}")
        Logger.debug("Prop1, not balanced - path is #{inspect(proof.path)}")
        Logger.debug("Prop1, not balanced - tree is #{inspect(t)}")
      end

      is_balanced
    end
  end


  # This proves that the inner key data is propagated properly upon delete
  property "deleting middle key in tree of variable size and ensuring state is well-formed" do
    forall {t, _pairs, sorted_keys, _key, _size} <- generate_tree(@middle_key_min_tree_size) do

      # NUMBER KEY
      # 1) Grab the key that is the inner key for the root.
      # 2) Delete that key
      # 3) Ensure in the new tree, the key is not found
      # 4) Ensure the new root search key is < than the previous inner key 
      # (since it has to pick it from the left subtree and we don't rebalance after a delete)
      # 5) To be more exact this key should be the next decreasing key after the deleted key in 
      # the sorted keys list

      # 1
      skey1 = t.root.search_key

      # Sanity check
      {:ok, _} = Tree.lookup(t, skey1)

      # 2
      {:ok, t} = Tree.delete(t, skey1)

      # 3
      {:error, _} = Tree.lookup(t, skey1)

      # 4
      skey2 = t.root.search_key
      assert true == skey2 < skey1

      # 5
      iskey1 = Enum.find_index(sorted_keys, fn x -> x == skey1 end)
      skey_smaller = Enum.at(sorted_keys, iskey1 - 1)
      assert skey_smaller == skey2

      true
    end
  end

  # We define a custom generator that generates the Merkel tree using a list of key-value
  # pairs with the branching specified via toggle params
  # (e.g. whether tree is left or right heavy at each level
  # We generate the tree iteratively through rotations or through building up from leaves via our generated list
  # Keys are binaries and values are term()

  def generate_tree(min_size \\ @min_tree_size) do
    let prop_list <- [
      # Note:
      # Didn't quite work (not able to sync the size of list with size of toggle list,
      # hence the Stream.cycle below)
      #
      # list: sized(size, resize(min(min_size, size), kv_pairs())),

      list: kv_pairs_list(min_size),
      toggle: tree_toggle_params()
    ] do
      {key, _v} = prop_list[:list] |> List.first
      kv_list = prop_list[:list]
      size = Enum.count(kv_list)
      keys = kv_list |> Enum.map(fn {k, _v} -> k end) |> Enum.sort()
      toggle = prop_list[:toggle]

      # Either we create the tree with a generate kv_list and toggle sequence, or
      # through iteratively constructing the tree one node at a time

      tree =
        oneof(
          [
            Helper.create_tree(kv_list, Stream.cycle(toggle)) |> create_helper(),
            create_tree_iteratively(kv_list)
          ]
        )

      {tree, kv_list, keys, key, size}
    end
  end

  ##############################################################################
  # HELPER FUNCTIONS


  def kv_pairs() do
    let pairs <- {key(), value()}, do: pairs
  end

  def kv_pairs_list() do
    let list <- non_empty(list(kv_pairs())), do: list
  end

  def kv_pairs_list(:atleast_four) do
    let [first <- kv_pairs(), second <- kv_pairs(), third <- kv_pairs(), many <- kv_pairs_list()] do
      [first, second, third | many]
    end
  end

  def kv_pairs_list(options) when is_atom(options) do
    # We ensure that the key-value pairs are unique, as are the keys themselves
    # (so we don't have smaller trees less than min size)

    case options do
      @min_tree_size ->
        unique_kv_pairs_list()
      @middle_key_min_tree_size ->
        generator = fn() -> kv_pairs_list(:atleast_four) end
        unique_kv_pairs_list(generator)
      true ->
        unique_kv_pairs_list()
    end
  end

  # Ensure no duplicate key value pairs e.g {"a", 1} and {"a", 1}
  # but also no duplicate keys e.g. {"a", 1} and {"a", 2}
  def unique_kv_pairs_list(generator \\ &Mod.kv_pairs_list()/0) when is_function(generator, 0) do
    such_that(l <- generator.(), when: length(Enum.uniq(l)) == length(l) and
      length(Enum.uniq(keys(l))) == length(keys(l)))
  end

  # Generate tree toggle booleans which denote whether tree is right or left heavy at each level
  # Provides variation in tree structure
  def tree_toggle_params() do
    let bools <- non_empty(list(boolean())), do: bools
  end

  # Key Generator
  def key() do
    # Prefer readable strings over potentially cryptic raw binary
    frequency(
        [
          {90, str_text(&Mod.text2/0)},
          {10, binary()}
        ]
      )
  end

  # Helper to extract key list from kv tuple list
  def keys([{k, _v} | _tail] = list) when is_binary(k), do: elem(Enum.unzip(list), 0)

  # Value Generator 
  def value() do
    # Prefer numbers, then atoms, then some form of binary
    frequency(
      [
        {60, number()},
        {20, atom()},
        {15, str_text(&Mod.text3/0)},
        {5, binary()}
      ]
    )
  end

  # Helper to extract value list from kv tuple list
  def values([{k, _v} | _tail] = list) when is_binary(k), do: elem(Enum.unzip(list), 1)

  # Provide more human readable text
  def str_text(lambda) when is_function(lambda, 0) do
    let chars <- non_empty(list(elements(lambda.()))) do
      to_string(chars)
    end
  end

  def text1(), do: text2() ++ text4()
  def text2(), do: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '
  def text3(), do: 'abcdefghijklmnopqrstuvwxyz'
  def text4(), do: ':;<=>?@ !#$%&\'()*+-./[\\]^_`{|}~'

end
