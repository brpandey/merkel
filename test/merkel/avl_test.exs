defmodule Merkel.AVLTest do
  use ExUnit.Case, async: true

  @root_hash "b79546dd73257070b95eefdaec251ce6c47085c92e898aa698b2a54975d4d3b6"


  test "multiple insertions, right skew" do

    # This is handled by AVL case 2) right right

    keys = [<<23>>, <<26>>, <<82>>, <<94>>]

    # Background info
    _ = """
    Enum.map(keys, fn k -> {k, Merkel.Crypto.hash(k)} end)
    [
    {<<23>>, "8f11b05da785e43e713d03774c6bd3405d99cd3024af334ffd68db663aa37034"},
    {<<26>>, "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d"},
    {"R", "8c2574892063f995fdf756bce07f46c1a5193e54cd52837ed91e32008ccf41ac"},
    {"^", "74cd9ef9c7e15f57bdad73c511462ca65cb674c46c49639c60f1b44650fa1dcb"}
    ]
    
    h1 = Enum.map(keys, fn k -> Merkel.Crypto.hash(k) end)
    ["8f11b05da785e43e713d03774c6bd3405d99cd3024af334ffd68db663aa37034",
    "58f7b0780592032e4d8602a3e8690fb2c701b2e1dd546e703445aabd6469734d",
    "8c2574892063f995fdf756bce07f46c1a5193e54cd52837ed91e32008ccf41ac",
    "74cd9ef9c7e15f57bdad73c511462ca65cb674c46c49639c60f1b44650fa1dcb"]
    
    h2 = Enum.chunk_every(h1,2) |> Enum.map(fn [l,r] -> Merkel.Crypto.hash_concat(l,r) end)
    ["ba5ff7e6a86ad51175277ab07ff95ed6ff57f7ebd0dfde1509b30628f31b64b0",
    "cb8f5e231563f77fac1e7fc8fb8304ec50a68736c8ff9f6afd2f73b27f78afd3"]
    
    h3 = Enum.chunk_every(h2,2) |> Enum.map(fn [l,r] -> Merkel.Crypto.hash_concat(l,r) end)
    ["b79546dd73257070b95eefdaec251ce6c47085c92e898aa698b2a54975d4d3b6"]
    """

    h1 = Enum.map(keys, fn k -> Merkel.Crypto.hash(k) end)
    h2 = Enum.chunk_every(h1,2) |> Enum.map(fn [l,r] -> Merkel.Crypto.hash_concat(l,r) end)
    h3 = Enum.chunk_every(h2,2) |> Enum.map(fn [l,r] -> Merkel.Crypto.hash_concat(l,r) end) |> List.first

    assert @root_hash = h3

    # We are reducing into Merkel, with nil keys
    tree = 
      Enum.reduce(keys, Merkel.new, fn k, acc -> 
        Merkel.insert(acc, {k, nil}) end)
    
    # With no avl rotations this would be - numbers are in binary
    
    # 3     <=23                3
    #      /    \
    # 0   23      <=26          2  heights are 0 and 2 or (abs 2), which is greater than 1
    #            /    \
    #          26      <=R      1
    #                  /   \
    #                 R     ^   0
    
    
    # after avl implemented
    
    #
    #             <=26          2
    #            /    \
    #        <=23      <=R      1
    #       /    \     /  \
    #      23     26  R    ^    0
    
    assert ~s(#Merkel.Tree<{4, {"#{@root_hash}", <<26>>, 2, {"ba5f..", <<23>>, 1, {"8f11..", <<23>>, 0}, {"58f7..", <<26>>, 0}}, {"cb8f..", "<=R..>", 1, {"8c25..", "R", 0}, {"74cd..", "^", 0}}}}>)
    ==  "#{inspect tree}"


    assert Merkel.tree_hash(tree) == h3
  end


  test "multiple insertions, left skew" do

    # This is handled by AVL case 1) left left

    keys = [<<94>>, <<82>>, <<26>>, <<23>>]

    # We are reducing into Merkel, with nil keys
    tree = 
      Enum.reduce(keys, Merkel.new, fn k, acc -> 
        Merkel.insert(acc, {k, nil}) end)

    
    # With no avl rotations this would be - numbers are in binary

    # 3         <=82    3
    #          /    \
    # 2       <=26   ^  0
    #        /    \
    # 1     <=23   R
    #      /    \
    # 0   23     26
    
    # after avl implemented
    
    #
    #             <=26          2
    #            /    \
    #        <=23      <=R      1
    #       /    \     /  \
    #      23     26  R    ^    0


    assert ~s(#Merkel.Tree<{4, {"#{@root_hash}", <<26>>, 2, {"ba5f..", <<23>>, 1, {"8f11..", <<23>>, 0}, {"58f7..", <<26>>, 0}}, {"cb8f..", "<=R..>", 1, {"8c25..", "R", 0}, {"74cd..", "^", 0}}}}>)
    ==  "#{inspect tree}"
    
  end




  test "multiple insertions, left right skew" do

    # This is handled by AVL case 3) left right

    keys = [<<82>>, <<94>>, <<23>>, <<26>>]

    # We are reducing into Merkel, with nil keys
    tree = 
      Enum.reduce(keys, Merkel.new, fn k, acc -> 
        Merkel.insert(acc, {k, nil}) end)

    
    # With no avl rotations this would be - numbers are in binary

    # 3              <=82       3
    #               /    \
    # 2          <=23     94    0
    #            /   \
    # 1         23    <=26   
    #                 /   \
    # 0             26    82     
    
    # after avl implemented

    #
    #             <=26          2
    #            /    \
    #        <=23      <=R      1
    #       /    \     /  \
    #      23     26  R    ^    0


    assert ~s(#Merkel.Tree<{4, {"#{@root_hash}", <<26>>, 2, {"ba5f..", <<23>>, 1, {"8f11..", <<23>>, 0}, {"58f7..", <<26>>, 0}}, {"cb8f..", "<=R..>", 1, {"8c25..", "R", 0}, {"74cd..", "^", 0}}}}>)
    ==  "#{inspect tree}"
    
  end


  test "multiple insertions, right left skew" do

    # This is handled by AVL case 4) right left

    keys = [<<23>>, <<82>>, <<94>>, <<26>>]

    # We are reducing into Merkel, with nil keys
    tree = 
      Enum.reduce(keys, Merkel.new, fn k, acc -> 
        Merkel.insert(acc, {k, nil}) end)

    
    # With no avl rotations this would be - numbers are in binary

    # 3      <=23
    #       /    \      
    # 0    23     <=82      2
    #            /    \
    #           <=26   94   1
    #          /    \
    #         26     82     0
    
    # after avl implemented

    #
    #             <=26          2
    #            /    \
    #        <=23      <=R      1
    #       /    \     /  \
    #      23     26  R    ^    0


    assert ~s(#Merkel.Tree<{4, {"#{@root_hash}", <<26>>, 2, {"ba5f..", <<23>>, 1, {"8f11..", <<23>>, 0}, {"58f7..", <<26>>, 0}}, {"cb8f..", "<=R..>", 1, {"8c25..", "R", 0}, {"74cd..", "^", 0}}}}>)
    ==  "#{inspect tree}"
    
  end

end
