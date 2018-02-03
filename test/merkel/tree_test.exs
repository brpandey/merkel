defmodule Merkel.TreeTest do
  use ExUnit.Case, async: true

  # Test tree create, lookup, keys, insert, delete, size, tree_hash operations

  require Logger

  import Merkel.TestHelper
  import Merkel.Crypto

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.BinaryNode, as: Node

  @list_size 20

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

      # Logger.debug("trees of size 2, 1: #{inspect tree} 2: #{inspect t0}")

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
    end
  end

  test "verify audit hashes work for each key in tree of size n and are height balanced" do
    # Build trees of size 1 to and including list size
    Enum.map(1..@list_size, fn size ->
      tdata = build_tree(size)

      {:ok, {t0, t1, t2}} = tdata |> Keyword.fetch(:trees)
      {:ok, valid_keys} = tdata |> Keyword.fetch(:valid_keys)

      sorted_vkeys = valid_keys |> Enum.sort()

      # Process each tree
      Enum.map([t0, t1, t2], fn tree ->
        tree_keys = Merkel.keys(tree) |> Enum.sort()

        # Sanity check 
        assert sorted_vkeys == tree_keys

        # Logger.debug("tree_keys are #{inspect tree_keys}")

        # Process each of the valid keys for each tree
        # Specifically we create an audit proof for each key, verify it
        # And ensure the audit path length reflects that the tree is balanced
        Enum.map(sorted_vkeys, fn k ->
          proof = Merkel.audit(tree, k)
          assert true == Merkel.verify(proof, Merkel.tree_hash(tree))

          # Let's make sure the tree is balanced
          length = Merkel.Audit.length(proof)
          balanced_height = round(:math.log2(size))
          is_balanced = abs(length - balanced_height) <= 1
          assert true == is_balanced

          # Logger.debug("audit trail length is #{length}, tree size is #{size}, log2size is #{balanced_height}")

          true
        end)
      end)
    end)
  end

  # This proves that the inner key data is propagated properly upon delete
  test "deleting middle key in tree of size n and ensuring state is well-formed" do
    # Build trees of size 4 to and including list size
    Enum.map(4..@list_size, fn size ->
      tdata = build_tree(size)

      {:ok, {t0, t1, t2}} = tdata |> Keyword.fetch(:trees)
      {:ok, valid_keys} = tdata |> Keyword.fetch(:valid_keys)

      sorted_vkeys = Enum.sort(valid_keys)

      # 1) Grab the key that is the inner key for the root.
      # 2) Delete that key
      # 3) Ensure in the new tree, the key is not found
      # 4) Ensure the new root search key is < than the previous inner key 
      # (since it has to pick it from the left subtree and we don't rebalance after a delete)

      # 5) To be more exact this key should be the next decreasing key after the deleted key in 
      # the sorted keys list

      l =
        Enum.map([t0, t1, t2], fn tree ->
          # 1
          skey1 = tree.root.search_key

          # Sanity check
          {:ok, _} = Merkel.lookup(tree, skey1)

          # 2
          {:ok, tree} = Merkel.delete(tree, skey1)
          # 3
          {:error, _} = Merkel.lookup(tree, skey1)

          skey2 = tree.root.search_key

          # 4
          assert true == skey2 < skey1

          iskey1 = Enum.find_index(sorted_vkeys, fn x -> x == skey1 end)
          skey_smaller = Enum.at(sorted_vkeys, iskey1 - 1)
          # 5
          assert skey_smaller == skey2

          # Logger.debug("valid keys #{inspect sorted_vkeys}")
          # Logger.debug("skey1 #{inspect skey1}, skey2 #{inspect skey2}, skey_smaller #{inspect skey_smaller}")

          true
        end)

      assert true == Enum.uniq(l) |> List.first()
    end)
  end

  test "compare tree at max display size and one over, by deleting and reinserting same keys" do
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

    tree_str_64 =
      "#Merkel.Tree<{64, {\"8c3e6d345e7de9c527deb10dbf419cad03eef58933fa50deb4b563fcb58fe5d0\", \"<=hu..>\", 7, {\"04f5..\", \"<=ea..>\", 6, {\"3329..\", \"<=ch..>\", 5, {\"3ff5..\", \"<=bi..>\", 4, {\"2d72..\", \"<=be..>\", 3, {\"a700..\", \"<=an..>\", 2, {\"27c7..\", \"<=al..>\", 1, {\"2f00..\", \"alligator\", 0}, {\"67a3..\", \"ant\", 0}}, {\"bc98..\", \"bear\", 0}}, {\"64a3..\", \"<=be..>\", 1, {\"62cb..\", \"bee\", 0}, {\"7a51..\", \"bird\", 0}}}, {\"76e6..\", \"<=ca..>\", 2, {\"af92..\", \"<=ca..>\", 1, {\"4812..\", \"camel\", 0}, {\"77af..\", \"cat\", 0}}, {\"d3af..\", \"<=ch..>\", 1, {\"65ef..\", \"cheetah\", 0}, {\"811e..\", \"chicken\", 0}}}}, {\"5998..\", \"<=de..>\", 3, {\"4721..\", \"<=co..>\", 2, {\"0e69..\", \"<=ch..>\", 1, {\"5a31..\", \"chimpanzee\", 0}, {\"beb1..\", \"cow\", 0}}, {\"188f..\", \"<=cr..>\", 1, {\"0276..\", \"crocodile\", 0}, {\"acf5..\", \"deer\", 0}}}, {\"b8a8..\", \"<=do..>\", 2, {\"c03a..\", \"<=do..>\", 1, {\"cd63..\", \"dog\", 0}, {\"532f..\", \"dolphin\", 0}}, {\"44b6..\", \"<=du..>\", 1, {\"2d23..\", \"duck\", 0}, {\"e73b..\", \"eagle\", 0}}}}}, {\"3cab..\", \"<=go..>\", 4, {\"600c..\", \"<=fl..>\", 3, {\"49b1..\", \"<=em..>\", 2, {\"a5af..\", \"<=el..>\", 1, {\"cd08..\", \"elephant\", 0}, {\"ff0e..\", \"emu\", 0}}, {\"b10a..\", \"<=fi..>\", 1, {\"b474..\", \"fish\", 0}, {\"f4de..\", \"fly\", 0}}}, {\"a38f..\", \"<=fr..>\", 2, {\"a9f1..\", \"<=fo..>\", 1, {\"776c..\", \"fox\", 0}, {\"74fa..\", \"frog\", 0}}, {\"0700..\", \"<=gi..>\", 1, {\"6bb7..\", \"giraffe\", 0}, {\"5480..\", \"goat\", 0}}}}, {\"e259..\", \"<=ha..>\", 3, {\"3311..\", \"<=go..>\", 2, {\"1da4..\", \"<=go..>\", 1, {\"1cf1..\", \"goldfish\", 0}, {\"c2d3..\", \"goose\", 0}}, {\"9fb3..\", \"<=ha..>\", 1, {\"12e1..\", \"hamster\", 0}, {\"0139..\", \"hawk\", 0}}}, {\"ee3e..\", \"<=hi..>\", 2, {\"86db..\", \"<=he..>\", 1, {\"8bf1..\", \"heron\", 0}, {\"db35..\", \"hippopotamus\", 0}}, {\"cdbb..\", \"<=ho..>\", 1, {\"fd62..\", \"horse\", 0}, {\"3790..\", \"hummingbird\", 0}}}}}}, {\"e3b3..\", \"<=ra..>\", 5, {\"9192..\", \"<=oc..>\", 4, {\"a8ef..\", \"<=li..>\", 3, {\"36e5..\", \"<=ki..>\", 2, {\"22ff..\", \"<=ka..>\", 1, {\"4a34..\", \"kangaroo\", 0}, {\"5897..\", \"kitten\", 0}}, {\"fb55..\", \"<=ki..>\", 1, {\"1a5a..\", \"kiwi\", 0}, {\"fc59..\", \"lion\", 0}}}, {\"209f..\", \"<=ly..>\", 2, {\"721f..\", \"<=lo..>\", 1, {\"a2e1..\", \"lobster\", 0}, {\"7c18..\", \"lynx\", 0}}, {\"1983..\", \"<=mo..>\", 1, {\"000c..\", \"monkey\", 0}, {\"5633..\", \"octopus\", 0}}}}, {\"22bd..\", \"<=ph..>\", 3, {\"849f..\", \"<=pa..>\", 2, {\"06b7..\", \"<=ow..>\", 1, {\"10f7..\", \"owl\", 0}, {\"a7cd..\", \"panda\", 0}}, {\"a01b..\", \"<=pe..>\", 1, {\"a095..\", \"peacock\", 0}, {\"be5b..\", \"pheasant\", 0}}}, {\"924f..\", \"<=pu..>\", 2, {\"c72e..\", \"<=pi..>\", 1, {\"f0b8..\", \"pig\", 0}, {\"6588..\", \"puppy\", 0}}, {\"ba72..\", \"<=ra..>\", 1, {\"d37d..\", \"rabbit\", 0}, {\"9950..\", \"rat\", 0}}}}}, {\"1e12..\", \"<=sp..>\", 4, {\"50da..\", \"<=sh..>\", 3, {\"9542..\", \"<=sc..>\", 2, {\"be92..\", \"<=sa..>\", 1, {\"aff7..\", \"salamander\", 0}, {\"631f..\", \"scorpion\", 0}}, {\"fcf5..\", \"<=se..>\", 1, {\"f0f6..\", \"seal\", 0}, {\"31fc..\", \"shark\", 0}}}, {\"2380..\", \"<=sn..>\", 2, {\"bc03..\", \"<=sh..>\", 1, {\"5c59..\", \"sheep\", 0}, {\"6215..\", \"snail\", 0}}, {\"fa2b..\", \"<=sn..>\", 1, {\"538d..\", \"snake\", 0}, {\"9bfa..\", \"spider\", 0}}}}, {\"a0e5..\", \"<=tu..>\", 3, {\"b562..\", \"<=st..>\", 2, {\"d733..\", \"<=sq..>\", 1, {\"960a..\", \"squirrel\", 0}, {\"094e..\", \"stork\", 0}}, {\"1d14..\", \"<=ti..>\", 1, {\"f15c..\", \"tiger\", 0}, {\"8d7d..\", \"turkey\", 0}}}, {\"970d..\", \"<=vu..>\", 2, {\"90c7..\", \"<=tu..>\", 1, {\"74dd..\", \"turtle\", 0}, {\"e988..\", \"vulture\", 0}}, {\"f76b..\", \"wolf\", 0}}}}}}}>"

    assert tree_str_64 == "#{inspect(tree)}"

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

    # Reinsert the same previously deleted left most key
    tree = Merkel.insert(tree, {skey2, "I feel refreshed"})

    # In this case the hashes are different when we try to reinsert
    # Hence reinsert the same key right after deleting doesn't
    # guarentee the merkle root will be the same

    new_new_tree_hash = Merkel.tree_hash(tree)
    assert new_tree_hash != new_new_tree_hash

    # recheck display

    # tree str 65
    new_tree_str_65 =
      "#Merkel.Tree<{65, {\"77fa5b3594f168ce62d76d4cbcf7fdda27cef7aaa10bc15b04b52ef6b2ec8257\", 7, \"...\", \"...\"}}>"

    # Check the display again
    assert new_tree_str_65 == "#{inspect(tree)}"
  end
end
