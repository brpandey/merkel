Merkel [![Hex.pm](https://img.shields.io/hexpm/v/merkel.svg)](https://hex.pm/packages/merkel)
==========
![Logo](https://raw.githubusercontent.com/brpandey/merkel/master/priv/images/merkel.png)

Implements a balanced, merkle binary hash tree. [Wikipedia](https://en.wikipedia.org/wiki/Merkle_tree) [Bitcoin](http://chimera.labs.oreilly.com/books/1234000001802/ch07.html#merkle_trees)

Merkle trees are a beautiful data structure for summarizing and verifying data integrity.
They are named in honor of distinguished computer scientist Ralph Merkle. This library is named
with a slight twist (le to el :arrows_clockwise:) to salute Angela Merkel's push for algorithmic transparency.

> “I am of the opinion that algorithms must be made more transparent so that one 
> can inform oneself as an interested citizen about questions like, ‘What influences my 
> behaviour on the internet and that of others?’” 
>
> “These algorithms — when they are not transparent — can lead to a distortion of our perception. 
> They narrow our breadth of information.” [Source](http://www.newsmediauk.org/Latest/merkel-calls-for-transparency-of-internet-giants-algorithms)

A Source of Data Integrity -
 
>  The reason why this works is that hashes propagate upward: if a malicious 
>  user attempts to swap in a fake transaction into the bottom of a Merkle tree, 
>  this change will cause a change in the node above, and then a change in the 
>  node above that, finally changing the root of the tree and therefore the hash 
>  of the block, causing the protocol to register it as a completely different block 
>  (almost certainly with an invalid proof of work)"
>   - [Ethereum](https://github.com/ethereum/wiki/wiki/White-Paper#merkle-trees)

## Noteworthy

* Uses AVL rotations :arrows_clockwise: to keep the tree balanced (relying on inner search keys for order property)
* Creation from list creates a balanced tree without any initial rotations or rehashings (RECOMMENDED)
* Supports key value storage, retrieval, and deletion
* Supports these hash algorithms: md5, ripemd160, sha, sha224, sha256, sha384, sha512 - See [crypto](http://erlang.org/doc/man/crypto.html#hash-2)
* Supports specifying a custom hash function with arity 1, which accepts a binary argument and returns a binary
* Provides proof of existence in verifiable format
* Keys are binary, and values are any type (use your discretion if you want the tree to be more compact)
* Supports simple serialization and deserialization
* Uses property testing

## Usage

* Note: Since keys are binaries we will use mostly String keys for visual clarity

* Helpful background

```elixir
iex> l = [{"zebra", 23}, {"daisy", "932"}, {"giraffe", 29}, {"anteater", "12"}, {"walrus", 49}]

iex> Enum.map(l, fn {k, _v} -> {k, Merkel.Crypto.hash(k)} end)

[
  {"zebra", "676cb75018edccf10fce6f376f2124e02c3293fa3fe8f953c75386198c714514"},
  {"daisy", "42029ef215256f8fa9fedb53542ee6553eef76027b116f8fac5346211b1e473c"},
  {"giraffe", "6bb7e067447139b18f6094d2d15bcc264affde89a8b9f5227fe5b38abd8b19d7"},
  {"anteater", "b0ce2ef96d43c0e0f83d57785f9a87b647065ca75360ca5e9de520e7f690c3f9"},
  {"walrus", "9671014645ce9d6f8bae746fded25064937658d712004bd01d8f4c093c387bf3"}
]
```


* Create new MHT

```elixir
iex> m1 = Merkel.new(l)
#Merkel.Tree<{5,
 {"f92f0f98d165457a4122bbe165aefa14928f45943f9b11880b51d720a1ad37c1", "<=gi..>",
  3,
  {"bbe4..", "<=da..>", 2,
   {"5ad2..", "<=an..>", 1, {"b0ce..", "anteater", 0}, {"4202..", "daisy", 0}},
   {"6bb7..", "giraffe", 0}},
  {"9b02..", "<=wa..>", 1, {"9671..", "walrus", 0}, {"676c..", "zebra", 0}}}}>
```

```elixir
iex> Merkel.keys(m1)
["anteater", "daisy", "giraffe", "walrus", "zebra"]
```

```elixir
iex> Merkel.to_list(m1)
[
  {"anteater", "12"},
  {"daisy", "932"},
  {"giraffe", 29},
  {"walrus", 49},
  {"zebra", 23}
]
```

```elixir
# Notes:
# double letter represents inner node search keys abbreviations,
# whose left values are <= to the search key, and right values are >
# gi is the root node with search key giraffe at height 3, with merkle hash: f92f..
# ant is abbreviated for anteater for space
# leaves are at height 0

 3                gi              3
              /       \
 2          da         wa         1
          /    \     /     \
 1     an   giraffe walrus zebra  0
      /  \
 0  ant   daisy
```


* Create new MHT with binary keys that aren't printable strings

```elixir
iex> l = [{<<231,23, 11>>, 23}, {<<108,1>>, "932"}, {<<21, 11>>, 29}, 
{"anteater" <> <<0>>, "12"}, {"walrus" <> <<0>>, 49}]
iex> Merkel.new(l)
#Merkel.Tree<{5,
 {"dfa6c9257e371e7717047eec853604174816f92238cf04057a720aabff405897", 
  <<108, 1>>, 3,
  {"7eb5..", "<=an..>", 2,
   {"eca4..", <<21, 11>>, 1, {"60c2..", <<21, 11>>, 0},
    {"7931..", <<97, 110, 116, 101, 97, 116, 101, 114, 0>>, 0}},
   {"a233..", <<108, 1>>, 0}},
  {"9ccb..", "<=wa..>", 1, {"5122..", <<119, 97, 108, 114, 117, 115, 0>>, 0},
   {"e93a..", <<231, 23, 11>>, 0}}}}>
```

```elixir
 3                <<108,1>>                     3
              /               \
 2          an                  wa              1
          /    \               /   \
 1   <<21,11> <<108,1>> <<119,97..> <<231,2..>  0
      /     \
 0 <<21,11>  <<97, 110..>
```


* Lookup key value

```elixir
iex> Merkel.lookup(m1, "walrus")
{:ok, 49}
```


* Insert key value pairs (and notice rotations)

```elixir
iex> m2 = Merkel.insert(m1, {"aardvark", 999})
#Merkel.Tree<{6,
 {"17b632f2e3ee68ef4bb880825c7d6bf3c674c9f0fb4d8f81a5654590e107f936", "<=gi..>",
  3,
  {"b1f2..", "<=an..>", 2,
   {"2fc5..", "<=aa..>", 1, {"cf9c..", "aardvark", 0},
    {"b0ce..", "anteater", 0}},
   {"92af..", "<=da..>", 1, {"4202..", "daisy", 0}, {"6bb7..", "giraffe", 0}}},
  {"9b02..", "<=wa..>", 1, {"9671..", "walrus", 0}, {"676c..", "zebra", 0}}}}>
```

```elixir
                 gi
             /        \
            an          wa
          /   \       /     \
       aa      da  walrus zebra
      / \     /   \
aardvark ant daisy giraffe
```

```elixir
iex> m3 = Merkel.insert(m2, {"elephant", "He's big"})
#Merkel.Tree<{7,
 {"af4b1fc2c7a9189aad3b4b60ee8d5235c7df262264e77ce62622f32725eb0424", "<=da..>",
  3,
  {"1779..", "<=an..>", 2,
   {"2fc5..", "<=aa..>", 1, {"cf9c..", "aardvark", 0},
    {"b0ce..", "anteater", 0}}, {"4202..", "daisy", 0}},
  {"add5..", "<=gi..>", 2,
   {"3b00..", "<=el..>", 1, {"cd08..", "elephant", 0}, {"6bb7..", "giraffe", 0}},
   {"9b02..", "<=wa..>", 1, {"9671..", "walrus", 0}, {"676c..", "zebra", 0}}}}}>
```

```elixir
                  da
              /         \
            an            gi
          /   \        /      \
       aa     daisy  el         wa
      / \           /  \        / \
aardvark ant elephant giraffe walr zebra
```


* Delete key

```elixir
# "daisy" is not an animal type, delete!
iex> {:ok, m4} = Merkel.delete(m3, "daisy")
{:ok,
 #Merkel.Tree<{6,
  {"9820eab565a08738588256687c806fa2df46b094f2eb8565568d573447361c0a",
   "<=an..>", 3,
   {"2fc5..", "<=aa..>", 1, {"cf9c..", "aardvark", 0},
    {"b0ce..", "anteater", 0}},
   {"add5..", "<=gi..>", 2,
    {"3b00..", "<=el..>", 1, {"cd08..", "elephant", 0},
     {"6bb7..", "giraffe", 0}},
    {"9b02..", "<=wa..>", 1, {"9671..", "walrus", 0}, {"676c..", "zebra", 0}}}}}>}
```

```elixir
                   an
              /         \
            aa            gi
          /   \        /      \
  aardvark  anteater el         wa
                    /  \        / \
             elephant giraffe walr zebra
```


* Insert key value

```elixir
iex> m5 = Merkel.insert(m4, {"penguin", :waddle})
#Merkel.Tree<{7,
 {"e79f6fa607ad5d0a8e93a8ba759b266d52a71471222f11fe1ab07ee89ef9f4a4", "<=gi..>",
  3,
  {"3c2f..", "<=an..>", 2,
   {"2fc5..", "<=aa..>", 1, {"cf9c..", "aardvark", 0},
    {"b0ce..", "anteater", 0}},
   {"3b00..", "<=el..>", 1, {"cd08..", "elephant", 0}, {"6bb7..", "giraffe", 0}}},
  {"0d77..", "<=wa..>", 2,
   {"b881..", "<=pe..>", 1, {"0a43..", "penguin", 0}, {"9671..", "walrus", 0}},
   {"676c..", "zebra", 0}}}}>
```

```elixir
                      gi
              /               \
            an                    wa
          /   \                /      \
       aa       el            pe      zebra
      / \      / \           /  \       
aardvark ant elep giraffe  penguin walrus
```


* Update value for key
* Get all keys

```elixir
iex> m6 = Merkel.insert(m5, {"walrus", {"eats too many fish"}})
..(same as above)..
iex> Merkel.lookup(m6, "walrus")
{:ok, {"eats too many fish"}}
iex> Merkel.keys(m6)
["aardvark", "anteater", "elephant", "giraffe", "penguin", "walrus", "zebra"]
```


* Create audit proof
* Note: the audit path is in a special tuple form reflective of audit trail order

```elixir
iex> proof = Merkel.audit(m6, "elephant")
%Merkel.Audit{
  key: "elephant",
  path: {{"2fc521eca930a09a28bad66d9a1380f7cfe895c77f17c7f8996a840471ba857d",
    {{}, "6bb7e067447139b18f6094d2d15bcc264affde89a8b9f5227fe5b38abd8b19d7"}},
   "0d77466195f02be2c49cf4d1f00a6b35d70b522ca7adbf9c22f769feca5cf29b"}
```

```elixir
==== denotes key
---- denotes audit hashes

                        gi
                /               \
             an                    wa (0d77..)
                                  -----
          /     \                /      \
(2fc5..) aa      el             pe      zebra
        ----
       /  \      / \           /  \       
 aardvark ant elep giraffe  penguin walrus
              ==== -------
                   (6bb7..)
```


* Verify audit proof

```elixir
iex> Merkel.verify(proof, Merkel.tree_hash(m6))
true
```


* Pretty print

```elixir
iex> Merkel.print(m6)

              0 zebra 676c..
          /
       2 <=wa..> 0d77..
          \
                     0 walrus 9671..
                 /
              1 <=pe..> b881..
                 \
                     0 penguin 0a43..
   /

3 <=gi..> e79f6fa607ad5d0a8e93a8ba759b266d52a71471222f11fe1ab07ee89ef9f4a4 (Merkle Root)

   \
                     0 giraffe 6bb7..
                 /
              1 <=el..> 3b00..
                 \
                     0 elephant cd08..
          /
       2 <=an..> 3c2f..
          \
                     0 anteater b0ce..
                 /
              1 <=aa..> 2fc5..
                 \
                     0 aardvark cf9c..
:ok
```


* Dump, Store, New

```elixir
iex> etf = Merkel.dump(m6)
<<131, 116, 0, 0, 0, 3, 100, 0, 10, 95, 95, 115, 116, 114, 117, 99, 116, 95, 95,
  100, 0, 28, 69, 108, 105, 120, 105, 114, 46, 77, 101, 114, 107, 101, 108, 46,
  66, 105, 110, 97, 114, 121, 72, 97, 115, 104, 84, 114, 101, 101, ...>>

iex> Merkel.store(m6, "./merkel.tmp")

iex> Merkel.new(etf: etf)
#Merkel.Tree<{7,
 {"e79f6fa607ad5d0a8e93a8ba759b266d52a71471222f11fe1ab07ee89ef9f4a4", "<=gi..>",
  3,
  {"3c2f..", "<=an..>", 2,
   {"2fc5..", "<=aa..>", 1, {"cf9c..", "aardvark", 0},
    {"b0ce..", "anteater", 0}},
   {"3b00..", "<=el..>", 1, {"cd08..", "elephant", 0}, {"6bb7..", "giraffe", 0}}},
  {"0d77..", "<=wa..>", 2,
   {"b881..", "<=pe..>", 1, {"0a43..", "penguin", 0}, {"9671..", "walrus", 0}},
   {"676c..", "zebra", 0}}}}>

iex> Merkel.new(path: "./merkel.tmp")
..(same as above)..
```


## Configure


* Configure the hash algorithm to override the default :sha256 (if necessary)

```elixir
# Override in config.exs
# Options are: :md5, :ripemd160, :sha, :sha224, :sha256, :sha384, :sha512, :sha256_sha256
config :merkel, hash_algorithm: :sha384
```


* Configure the hash function to pass in a &Mod.fun/1 (if necessary)

```elixir
# Override in config.exs
# Function must be specified using &Mod.fun/arity format
# Function have arity 1, accepting a binary and then returning a binary
# Note if you have a custom function like: 
#  &(:crypto.hash(:ripemd160, :crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower))

# Wrap it in a module and function then pass the MFA
config :merkel, hash_function: &MyMod.ripemd160_sha256_hash/1 

# another

config :merkel, hash_function: &Merkel.Crypto.sha256_2_hash/1

```


## Install


* Add to mix dependency list in mix.exs

```elixir
def deps do
  [{:merkel, "~> 1.0"}]
end
```

## Property Testing

Now uses PropCheck, see the interactive IEX [Steps](https://github.com/brpandey/merkel/blob/master/PROPTEST.md)

```elixir
iex(11)> produce(such_that {_tree, _kv_list, _keys, _key, size} 
  <- Merkel.TreePropTest.generate_tree(:option_min_one_tree), when: size == 3)
{:ok,
 {#Merkel.Tree<{3,
   {"a28b2edeeb8e72881763e0ece89c257dc7a317e2bfcd53aefd48ed17059ddfda",
    "<=oE..>", 2,
    {"d890..", "<=7F..>", 1, {"e818..", "7FjDV", 0}, {"cf21..", "oEr", 0}},
    {"95df..", "tgSA 4Nz", 0}}}>,
  [
    {"oEr", -0.057744741577119},
    {"tgSA 4Nz", -6.749199934830595},
    {"7FjDV", :"5Ô\f\x96"}
  ], ["7FjDV", "oEr", "tgSA 4Nz"], "oEr", 3}}
```

## Thanks!

Thanks for the great Erlang/Elixir/Go/Clojure/Java open source merkle tree 
related projects for the inspiration (including [merklet](https://github.com/ferd/merklet) and [gb_merkle_trees](https://github.com/KrzysiekJ/gb_merkle_trees) )

Cheers
Bibek Pandey
