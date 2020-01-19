defmodule Merkel.TestDataHelper do
  @moduledoc """
  Contains test data
  """

    # size 20
  @list1 [
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

  @tree_str_64 "#Merkel.Tree<{64, {\"8c3e6d345e7de9c527deb10dbf419cad03eef58933fa50deb4b563fcb58fe5d0\", \"<=hu..>\", 7, {\"04f5..\", \"<=ea..>\", 6, {\"3329..\", \"<=ch..>\", 5, {\"3ff5..\", \"<=bi..>\", 4, {\"2d72..\", \"<=be..>\", 3, {\"a700..\", \"<=an..>\", 2, {\"27c7..\", \"<=al..>\", 1, {\"2f00..\", \"alligator\", 0}, {\"67a3..\", \"ant\", 0}}, {\"bc98..\", \"bear\", 0}}, {\"64a3..\", \"<=be..>\", 1, {\"62cb..\", \"bee\", 0}, {\"7a51..\", \"bird\", 0}}}, {\"76e6..\", \"<=ca..>\", 2, {\"af92..\", \"<=ca..>\", 1, {\"4812..\", \"camel\", 0}, {\"77af..\", \"cat\", 0}}, {\"d3af..\", \"<=ch..>\", 1, {\"65ef..\", \"cheetah\", 0}, {\"811e..\", \"chicken\", 0}}}}, {\"5998..\", \"<=de..>\", 3, {\"4721..\", \"<=co..>\", 2, {\"0e69..\", \"<=ch..>\", 1, {\"5a31..\", \"chimpanzee\", 0}, {\"beb1..\", \"cow\", 0}}, {\"188f..\", \"<=cr..>\", 1, {\"0276..\", \"crocodile\", 0}, {\"acf5..\", \"deer\", 0}}}, {\"b8a8..\", \"<=do..>\", 2, {\"c03a..\", \"<=do..>\", 1, {\"cd63..\", \"dog\", 0}, {\"532f..\", \"dolphin\", 0}}, {\"44b6..\", \"<=du..>\", 1, {\"2d23..\", \"duck\", 0}, {\"e73b..\", \"eagle\", 0}}}}}, {\"3cab..\", \"<=go..>\", 4, {\"600c..\", \"<=fl..>\", 3, {\"49b1..\", \"<=em..>\", 2, {\"a5af..\", \"<=el..>\", 1, {\"cd08..\", \"elephant\", 0}, {\"ff0e..\", \"emu\", 0}}, {\"b10a..\", \"<=fi..>\", 1, {\"b474..\", \"fish\", 0}, {\"f4de..\", \"fly\", 0}}}, {\"a38f..\", \"<=fr..>\", 2, {\"a9f1..\", \"<=fo..>\", 1, {\"776c..\", \"fox\", 0}, {\"74fa..\", \"frog\", 0}}, {\"0700..\", \"<=gi..>\", 1, {\"6bb7..\", \"giraffe\", 0}, {\"5480..\", \"goat\", 0}}}}, {\"e259..\", \"<=ha..>\", 3, {\"3311..\", \"<=go..>\", 2, {\"1da4..\", \"<=go..>\", 1, {\"1cf1..\", \"goldfish\", 0}, {\"c2d3..\", \"goose\", 0}}, {\"9fb3..\", \"<=ha..>\", 1, {\"12e1..\", \"hamster\", 0}, {\"0139..\", \"hawk\", 0}}}, {\"ee3e..\", \"<=hi..>\", 2, {\"86db..\", \"<=he..>\", 1, {\"8bf1..\", \"heron\", 0}, {\"db35..\", \"hippopotamus\", 0}}, {\"cdbb..\", \"<=ho..>\", 1, {\"fd62..\", \"horse\", 0}, {\"3790..\", \"hummingbird\", 0}}}}}}, {\"e3b3..\", \"<=ra..>\", 5, {\"9192..\", \"<=oc..>\", 4, {\"a8ef..\", \"<=li..>\", 3, {\"36e5..\", \"<=ki..>\", 2, {\"22ff..\", \"<=ka..>\", 1, {\"4a34..\", \"kangaroo\", 0}, {\"5897..\", \"kitten\", 0}}, {\"fb55..\", \"<=ki..>\", 1, {\"1a5a..\", \"kiwi\", 0}, {\"fc59..\", \"lion\", 0}}}, {\"209f..\", \"<=ly..>\", 2, {\"721f..\", \"<=lo..>\", 1, {\"a2e1..\", \"lobster\", 0}, {\"7c18..\", \"lynx\", 0}}, {\"1983..\", \"<=mo..>\", 1, {\"000c..\", \"monkey\", 0}, {\"5633..\", \"octopus\", 0}}}}, {\"22bd..\", \"<=ph..>\", 3, {\"849f..\", \"<=pa..>\", 2, {\"06b7..\", \"<=ow..>\", 1, {\"10f7..\", \"owl\", 0}, {\"a7cd..\", \"panda\", 0}}, {\"a01b..\", \"<=pe..>\", 1, {\"a095..\", \"peacock\", 0}, {\"be5b..\", \"pheasant\", 0}}}, {\"924f..\", \"<=pu..>\", 2, {\"c72e..\", \"<=pi..>\", 1, {\"f0b8..\", \"pig\", 0}, {\"6588..\", \"puppy\", 0}}, {\"ba72..\", \"<=ra..>\", 1, {\"d37d..\", \"rabbit\", 0}, {\"9950..\", \"rat\", 0}}}}}, {\"1e12..\", \"<=sp..>\", 4, {\"50da..\", \"<=sh..>\", 3, {\"9542..\", \"<=sc..>\", 2, {\"be92..\", \"<=sa..>\", 1, {\"aff7..\", \"salamander\", 0}, {\"631f..\", \"scorpion\", 0}}, {\"fcf5..\", \"<=se..>\", 1, {\"f0f6..\", \"seal\", 0}, {\"31fc..\", \"shark\", 0}}}, {\"2380..\", \"<=sn..>\", 2, {\"bc03..\", \"<=sh..>\", 1, {\"5c59..\", \"sheep\", 0}, {\"6215..\", \"snail\", 0}}, {\"fa2b..\", \"<=sn..>\", 1, {\"538d..\", \"snake\", 0}, {\"9bfa..\", \"spider\", 0}}}}, {\"a0e5..\", \"<=tu..>\", 3, {\"b562..\", \"<=st..>\", 2, {\"d733..\", \"<=sq..>\", 1, {\"960a..\", \"squirrel\", 0}, {\"094e..\", \"stork\", 0}}, {\"1d14..\", \"<=ti..>\", 1, {\"f15c..\", \"tiger\", 0}, {\"8d7d..\", \"turkey\", 0}}}, {\"970d..\", \"<=vu..>\", 2, {\"90c7..\", \"<=tu..>\", 1, {\"74dd..\", \"turtle\", 0}, {\"e988..\", \"vulture\", 0}}, {\"f76b..\", \"wolf\", 0}}}}}}}>"


  # Access methods
  def list1(), do: @list1
  def list2(), do: @list2
  def list2_size(), do: @list2_size
  def tree_str_64(), do: @tree_str_64
end
