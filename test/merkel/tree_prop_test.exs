defmodule Merkel.TreePropTest do
  use ExUnit.Case, async: true

  # An attempt at doing some property-like testing
  # of the tree module without a formal property testing library

  require Logger

  import Merkel.TestHelper

  @med_size 20
  @big_size 65

  # Run before all tests
  setup_all do
    # seed random number generator with random seed
    <<a::32, b::32, c::32>> = :crypto.strong_rand_bytes(12)
    r_seed = {a, b, c}

    _ = :rand.seed(:exsplus, r_seed)

    :ok
  end

  test "verify audit hashes work for each key in tree of size n and are height balanced" do
    # Build trees of size 1 to and including big size
    Enum.map(1..@big_size, fn size ->
      tdata = big_tree(size)

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
          is_balanced = abs(length - balanced_height) <= 2

          # Logger.debug("audit trail length is #{length}, tree size is #{size}, log2size is #{balanced_height}")

          if !is_balanced do
            Logger.debug("key is #{k}")
            Logger.debug("path is #{inspect(proof.path)}")
            Logger.debug("tree is #{inspect(tree)}")
          end

          assert true == is_balanced

          true
        end)
      end)
    end)
  end

  # This proves that the inner key data is propagated properly upon delete
  test "deleting middle key in tree of size n and ensuring state is well-formed" do
    # Build trees of size 4 to and including size
    Enum.map(4..@med_size, fn size ->
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
