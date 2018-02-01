ExUnit.start()

defmodule Merkel.TestHelper do
  @moduledoc "Helper routines to make test state easier to setup / run"
  
  import Merkel.Helper
  alias Merkel.BinaryHashTree, as: Tree


  @list [{"zebra", 23}, {<<9,9,2>>, "992"}, {"giraffe", nil}, {"anteater", "12"}, 
         {"walrus", 49}, {<<23,1,0>>, 99}, {<<100,2>>, :furry}, {"lion", "3"}, 
         {"kangaroo", nil}, {"cow", 99}, {"leopard", :fast}, {<<3,2,1>>, nil}, 
         {"kingfisher", :greedy}, {"turtle", "shell"}, {"lynx", 10}, {<<8>>, ""}, 
         {<<76>>, :new}, {"hippo", 10}, {"elephant", "gray"}, {"aardvark", 7}]
  
  @list_size 20


  # Routines to construct the tree of desired size, with three tree types
  # The three tree types are merely to provide some diversity in tree formation 
  # since we are implementing a dynamic tree library with rotations

  # Along with the trees we provide a convenience list of relevant tree data
  def build_tree(size) when is_integer(size), do: build_tree(%{size: size})
  def build_tree(%{size: size}) when size > 0 and size <= @list_size do

    list = Enum.shuffle(@list)
    
    pairs = Enum.take(list, size)
    valid_keys = Enum.take(list, size) |> Enum.map(fn {k,_v} -> k end)
    invalid_keys = Enum.take(list, size - Enum.count(list)) |> Enum.map(fn {k, _v} -> k end)
    valid_values = Enum.take(list, size) |> Enum.map(fn {_k,v} -> v end)
    
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
