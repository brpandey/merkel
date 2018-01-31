defmodule Merkel.AVLTest do
  use ExUnit.Case, async: true


  test "multiple insertions, right skew" do

    # This is handled by AVL case 2) right right

    tree = 
      Merkel.new
      |> Merkel.insert({<<23>>,34})
      |> Merkel.insert({<<26>>,76})
      |> Merkel.insert({<<82>>,40})
      |> Merkel.insert({<<94>>,36})
    
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


    assert ~s(#Merkel.Tree<{4, {"b79546dd73257070b95eefdaec251ce6c47085c92e898aa698b2a54975d4d3b6", <<26>>, 2, {"ba5f..", <<23>>, 1, {"8f11..", <<23>>, 0}, {"58f7..", <<26>>, 0}}, {"cb8f..", "<=R..>", 1, {"8c25..", "R", 0}, {"74cd..", "^", 0}}}}>)
    ==  "#{inspect tree}"
    
  end

end
