Merkel
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

And
> "The purpose of the Merkle tree [in Bitcoin] is to allow the data in a block to be delivered piecemeal: 
> a node can download only the header of a block from one source, the small part of the tree relevant to them 
> from another source, and still be aassured that all of the data is correct. The reason why this works is that 
> hashes propagate upward: if a malicious user attempts to swap in a fake transaction into the bottom of a 
> Merkle tree, this change will cause a change in the node above, and then a change in the node above that, 
> finally changing the root of the tree and therefore the hash of the block, causing the protocol to 
> register it as a completely different block (almost certainly with an invalid proof of work)"
> - [Ethereum](https://github.com/ethereum/wiki/wiki/White-Paper#merkle-trees)

## Noteworthy

* Uses AVL rotations :arrows_clockwise: to keep the tree balanced (relying on inner search keys for order property)
* Creation from list creates a balanced tree without any initial rotations or rehashings (RECOMMENDED)
* Support key value storage, retrieval, deletion
* Supports these hash algorithms: md5, ripemd160, sha, sha224, sha256, sha384, sha512 - See [crypto](http://erlang.org/doc/man/crypto.html#hash-2)
* Supports double hashing
* Provides proof of existence in verifiable format
* Keys are binary, and values are any type (use your discretion if you want the tree to be compact)

## Usage

* Note: Since keys are binaries we will use mostly String keys for clarity

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


* Lookup key

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
iex> Merkel.verify(proof, Merkel.tree_hash(m))
true
```

## Configure

* Configure the hash algorithm to override the default :sha256 (if necessary)

```elixir
# Override in config.exs
# Options are: :md5, :ripemd160, :sha, :sha224, :sha256, :sha384, :sha512
config :merkel, hash_algorithm: :sha384
```

* Configure the hash apply to override the default :single (if necessary)

```elixir
# Override in config.exs
# Options are: :single, :double
# E.g. Bitcoin does a double :sha256 hash, meaning it hashes twice
config :merkel, hash_apply: :double             
```

## Future

* Parallel insertions / deletions? :)


## Thanks!

Thanks for the great Erlang/Elixir open source merkle tree related projects for the inspiration

Bibek Pandey
