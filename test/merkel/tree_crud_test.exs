defmodule Merkel.TreeCrudTest do
  use ExUnit.Case, async: true

  # Test tree create, lookup, keys, insert, delete, size, tree_hash operations

  require Logger

  import Merkel.TestHelper
  import Merkel.Crypto

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node

  # Run before all tests
  setup_all do
    # seed random number generator with random seed
    <<a::32, b::32, c::32>> = :crypto.strong_rand_bytes(12)
    r_seed = {a, b, c}

    _ = :rand.seed(:exsplus, r_seed)

    :ok
  end

  # nil

  test "empty tree" do
    pair = {k0, _v} = {"starfish", :blue}
    pair2 = {"starfish", "green"}

    empty = Merkel.new()
    empty2 = Merkel.new([])

    assert empty == empty2

    assert %Tree{size: 0, root: nil} == empty

    # lookup item
    assert {:error, "key: starfish not found in tree"} == Merkel.lookup(empty, k0)

    # get keys list
    assert [] == Merkel.keys(empty)

    root_hash = "3755b417b0f937026ac1b867a397d6dec80dfd463c232c2daaf1de974b93da82"

    assert root_hash == hash(k0)

    # insert item
    root = %Node{
      key_hash: root_hash,
      search_key: k0,
      key: k0,
      value: :blue,
      height: 0,
      left: nil,
      right: nil
    }

    tree = %Tree{size: 1, root: root}

    assert tree == Merkel.insert(empty, pair)

    # Test update
    tree = Merkel.insert(tree, pair2)
    assert {:ok, "green"} == Merkel.lookup(tree, k0)

    # delete item
    assert {:error, "key: starfish not found in tree"} == Merkel.delete(empty, k0)

    # size
    assert 0 == Merkel.size(empty)

    # root hash
    assert nil == Merkel.tree_hash(empty)

    # audit
    proof = %Merkel.Audit{key: "starfish", path: nil}
    assert proof == Merkel.audit(empty, "starfish")
    assert false == Merkel.verify(proof, nil)

    # print
    assert :ok == Merkel.print(empty)
  end

  # root

  describe "tree of size 1" do
    setup :build_tree

    @tag size: 1
    test "crud", %{
      size: _sz,
      trees: {t0, t1, t2},
      valid_keys: vkeys,
      invalid_keys: ikeys,
      valid_values: vvs
    } do
      assert t0 == t1
      assert t1 == t2

      pair = {k2, v2} = {"starfish", :blue}

      k1 = Enum.at(vkeys, 0)
      v1 = Enum.at(vvs, 0)
      ik = Enum.at(ikeys, 0)

      k1_hash = hash(k1)

      root = %Node{
        key_hash: k1_hash,
        search_key: k1,
        key: k1,
        value: v1,
        height: 0,
        left: nil,
        right: nil
      }

      tree = %Tree{size: 1, root: root}

      assert Node.dump(root) == Node.dump(tree.root)
      assert tree == t0

      # lookup item
      assert {:ok, ^v1} = Merkel.lookup(t0, k1)
      assert {:error, _} = Merkel.lookup(t0, ik)

      # get keys list
      assert vkeys == Merkel.keys(t0)

      # setup for insert item

      k2_hash = hash(k2)

      k1_node = %Node{
        key_hash: k1_hash,
        search_key: k1,
        key: k1,
        value: v1,
        height: 0,
        left: nil,
        right: nil
      }

      k2_node = %Node{
        key_hash: k2_hash,
        search_key: k2,
        key: k2,
        value: v2,
        height: 0,
        left: nil,
        right: nil
      }

      root =
        case k1 > k2 do
          true ->
            root_hash = hash_concat(k2_hash, k1_hash)

            %Node{
              key_hash: root_hash,
              search_key: k2,
              key: nil,
              value: nil,
              height: 1,
              left: k2_node,
              right: k1_node
            }

          false ->
            root_hash = hash_concat(k1_hash, k2_hash)

            %Node{
              key_hash: root_hash,
              search_key: k1,
              key: nil,
              value: nil,
              height: 1,
              left: k1_node,
              right: k2_node
            }
        end

      # insert item
      new_tree = %Tree{size: 2, root: root}

      assert new_tree == Merkel.insert(t0, pair)

      empty = %Tree{size: 0, root: nil}

      # delete item
      assert {:error, _} = Merkel.delete(t0, ik)
      assert {:ok, empty} == Merkel.delete(t0, k1)

      # size
      assert 1 == Merkel.size(t0)

      # root hash 
      # A newly inserted tree, and its hash should be different than the old tree - Hence definition
      assert k1_hash == Merkel.tree_hash(t0)
      assert k1_hash != Merkel.tree_hash(new_tree)

      # audit
      proof = %Merkel.Audit{key: k1, path: {}}
      assert proof == Merkel.audit(t0, k1)
      assert true == Merkel.verify(proof, k1_hash)

      # print
      assert :ok == Merkel.print(t0)
    end
  end

  # root 
  #  / \
  # l   r

  # to

  #       root                 root
  #      /    \               /    \
  #  inner     r             l      inner
  #  / \                            /    \
  # l   r                          l      r

  # (Manually going through expectations in long function)
  describe "tree of size 2" do
    setup :build_tree

    @tag size: 2
    test "crud", %{
      size: _sz,
      trees: {t0, t1, t2},
      valid_keys: vkeys,
      invalid_keys: ikeys,
      valid_values: vvs
    } do
      assert t0 == t1
      assert t1 == t2

      pair = {k3, v3} = {"centipede", :long}

      k1 = Enum.at(vkeys, 0)
      k2 = Enum.at(vkeys, 1)
      v1 = Enum.at(vvs, 0)
      v2 = Enum.at(vvs, 1)

      ik = Enum.at(ikeys, 0)

      k1_hash = hash(k1)
      k2_hash = hash(k2)

      # Construct a tree of size 2
      k1_node = %Node{
        key_hash: k1_hash,
        search_key: k1,
        key: k1,
        value: v1,
        height: 0,
        left: nil,
        right: nil
      }

      k2_node = %Node{
        key_hash: k2_hash,
        search_key: k2,
        key: k2,
        value: v2,
        height: 0,
        left: nil,
        right: nil
      }

      root =
        case k1 > k2 do
          true ->
            root_hash = hash_concat(k2_hash, k1_hash)

            %Node{
              key_hash: root_hash,
              search_key: k2,
              key: nil,
              value: nil,
              height: 1,
              left: k2_node,
              right: k1_node
            }

          false ->
            root_hash = hash_concat(k1_hash, k2_hash)

            %Node{
              key_hash: root_hash,
              search_key: k1,
              key: nil,
              value: nil,
              height: 1,
              left: k1_node,
              right: k2_node
            }
        end

      t0_hash_size2 = root.key_hash

      tree = %Tree{size: 2, root: root}

      # Ensure the tree of size two matches t0
      assert tree == t0

      # lookup item
      assert {:ok, ^v1} = Merkel.lookup(t0, k1)
      assert {:error, _} = Merkel.lookup(t0, ik)

      # get keys list
      assert vkeys |> Enum.sort() == Merkel.keys(t0) |> Enum.sort()

      # setup for insert item, creating a tree of size 3
      k3_hash = hash(k3)

      k3_node = %Node{
        key_hash: k3_hash,
        search_key: k3,
        key: k3,
        value: v3,
        height: 0,
        left: nil,
        right: nil
      }

      root =
        case k3 > root.search_key do
          true ->
            inner =
              if k3 > root.right.search_key do
                h = hash_concat(root.right.key_hash, k3_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: root.right.key,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: root.right,
                  right: k3_node
                }
              else
                h = hash_concat(k3_hash, root.right.key_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: k3,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: k3_node,
                  right: root.right
                }
              end

            # Update root hash
            root_hash = hash_concat(root.left.key_hash, inner.key_hash)

            %Node{root | height: 2, key_hash: root_hash, right: inner}

          false ->
            inner =
              if k3 > root.left.search_key do
                h = hash_concat(root.left.key_hash, k3_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: root.left.key,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: root.left,
                  right: k3_node
                }
              else
                h = hash_concat(k3_hash, root.left.key_hash)
                # Create new inner node
                %Node{
                  key_hash: h,
                  search_key: k3,
                  key: nil,
                  value: nil,
                  height: 1,
                  left: k3_node,
                  right: root.left
                }
              end

            # Update root hash
            root_hash = hash_concat(inner.key_hash, root.right.key_hash)

            %Node{root | height: 2, key_hash: root_hash, left: inner}
        end

      # insert item
      tree_new = %Tree{size: 3, root: root}

      assert tree_new == Merkel.insert(t0, pair)

      # The tree hash for size 3 should not be equal to the tree hash for size 2
      # Hence the definition!
      assert t0_hash_size2 != Merkel.tree_hash(tree_new)

      # print
      assert :ok == Merkel.print(tree_new)

      # delete item in newly inserted tree, ensure it matches previous tree
      assert {:error, _} = Merkel.delete(tree_new, ik)
      assert {:ok, tree} == Merkel.delete(tree_new, k3)

      # size
      assert 2 == Merkel.size(t0)

      # root hash, since the tree is very small only 2, inserting an extra
      # and deleting doesn't change the hashes of the two trees 
      # but will for larger trees
      assert ^t0_hash_size2 = Merkel.tree_hash(t0)

      # audit
      assert true == Merkel.verify(Merkel.audit(t0, k1), t0_hash_size2)

      # print
      assert :ok == Merkel.print(t0)
    end
  end

  test "compare tree at max display size and one size larger, by deleting and reinserting same keys" do
    tdata = big_tree()

    {:ok, {tree, _t1, _t2}} = tdata |> Keyword.fetch(:trees)
    {:ok, valid_keys} = tdata |> Keyword.fetch(:valid_keys)

    sorted_vkeys = Enum.sort(valid_keys)

    # Check to see the tree's display
    tree_str_65 =
      "#Merkel.Tree<{65, {\"9ca159ef40742ccdaa45bcce51c0fb48534997f72060b0eb4bc5c31ad85513da\", 7, \"...\", \"...\"}}>"

    assert tree_str_65 == "#{inspect(tree)}"

    tree_hash = Merkel.tree_hash(tree)

    # Grab the last key and third key :)
    skey1 = Enum.at(sorted_vkeys, -1)
    skey2 = Enum.at(sorted_vkeys, 2)

    # Sanity check
    {:ok, _} = Merkel.lookup(tree, skey1)

    # Delete right most key
    {:ok, tree} = Merkel.delete(tree, skey1)

    # Ensure in the new tree, the key is not found
    {:error, _} = Merkel.lookup(tree, skey1)

    assert tree_str_64() == "#{inspect(tree)}"

    # Insert the same previously deleted key
    tree = Merkel.insert(tree, {skey1, "wakawakawaka"})

    # The tree hash is not guarenteed to be the same
    # since we've udpated inner search keys, but in this case it is 
    # the same since it is the right most element
    # and the tree structure didn't change (no rebalancing and no inner search keys reupdate)

    new_tree_hash = Merkel.tree_hash(tree)
    assert tree_hash == new_tree_hash

    # Check the display again
    assert tree_str_65 == "#{inspect(tree)}"

    # Update the key with a new value
    tree = Merkel.insert(tree, {skey1, "keep calm and carry on"})

    # The tree hash is the same because the key is the same we're just inserting the value
    assert new_tree_hash == Merkel.tree_hash(tree)

    # Check the display again
    assert tree_str_65 == "#{inspect(tree)}"

    # Delete the third left most key
    {:ok, tree} = Merkel.delete(tree, skey2)

    # Reinsert the same previously deleted third left most key
    tree = Merkel.insert(tree, {skey2, "I feel refreshed"})

    # In this case the hashes are different when we try to reinsert
    # Hence reinsert the same key right after deleting doesn't
    # guarantee the merkle root will be the same

    new_new_tree_hash = Merkel.tree_hash(tree)
    assert new_tree_hash != new_new_tree_hash

    new_tree_str_65 =
      "#Merkel.Tree<{65, {\"77fa5b3594f168ce62d76d4cbcf7fdda27cef7aaa10bc15b04b52ef6b2ec8257\", 7, \"...\", \"...\"}}>"

    # Check the display again, it has a new merkle root
    assert new_tree_str_65 == "#{inspect(tree)}"
  end
end
