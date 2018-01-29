Merkel
==========
![Logo](https://raw.githubusercontent.com/brpandey/merkel/master/priv/images/merkel.png)

Implements a dynamic, merkle binary hash tree. [Wikipedia](https://en.wikipedia.org/wiki/Merkle_tree) [Bitcoin](http://chimera.labs.oreilly.com/books/1234000001802/ch07.html#merkle_trees)

Merkle trees are a beautiful data structure for summarizing and verifying data integrity.
They are named in honor of distinguished computer scientist Ralph Merkle. This library is named
with a slight twist (or rotation) to salute Angela Merkel's push for algorithmic transparency.

> Merkel Urges Transparency For Internet Giants’ Algorithms
>
> “I am of the opinion that algorithms must be made more transparent so that one 
> can inform oneself as an interested citizen about questions like, ‘What influences my 
> behaviour on the internet and that of others?’” 
>
> “These algorithms — when they are not transparent — can lead to a distortion of our perception. 
> They narrow our breadth of information.”
>> 
> [Source](http://www.newsmediauk.org/Latest/merkel-calls-for-transparency-of-internet-giants-algorithms)

## Noteworthy

* Uses AVL rotations to keep the tree balanced
* Initial creation from list creates a balanced tree without any initial rotations or rehashings

## Usage

* Helpful background

```elixir
iex> l = [{"zebra", 23}, {"daisy", "932"}, {"giraffe", 29}, {"anteater", "12"}, {"walrus", 49}]

iex> Enum.map(l, fn {k, _v} -> {k, Merkel.BinaryHashTree.hash(k)} end)

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
 {"f92f0f98d165457a4122bbe165aefa14928f45943f9b11880b51d720a1ad37c1", "giraffe",
  3,
  {"bbe4b971...", "daisy", 2,
   {"5ad27451...", "anteater", 1, {"b0ce2ef9...", "anteater", 0, nil, nil},
    {"42029ef2...", "daisy", 0, nil, nil}},
   {"6bb7e067...", "giraffe", 0, nil, nil}},
  {"9b02597c...", "walrus", 1, {"96710146...", "walrus", 0, nil, nil},
   {"676cb750...", "zebra", 0, nil, nil}}}>
```

```elixir
                  g
              /       \
             d          w
          /    \     /     \
        a   giraffe walrus zebra
      /   \
    ant   daisy
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
 {"17b632f2e3ee68ef4bb880825c7d6bf3c674c9f0fb4d8f81a5654590e107f936", "giraffe",
  3,
  {"b1f2e847...", "anteater", 2,
   {"2fc521ec...", "aardvark", 1, {"cf9c1cb8...", "aardvark", 0, nil, nil},
    {"b0ce2ef9...", "anteater", 0, nil, nil}},
   {"92af87b4...", "daisy", 1, {"42029ef2...", "daisy", 0, nil, nil},
    {"6bb7e067...", "giraffe", 0, nil, nil}}},
  {"9b02597c...", "walrus", 1, {"96710146...", "walrus", 0, nil, nil},
   {"676cb750...", "zebra", 0, nil, nil}}}}>
```

```elixir
                 g
             /        \
            a           w
          /   \       /     \
       aa       d  walrus zebra
      / \     /   \
aardvark ant daisy giraffe
```

```elixir
iex> m3 = Merkel.insert(m2, {"elephant", "He's big"})
#Merkel.Tree<{7,
 {"af4b1fc2c7a9189aad3b4b60ee8d5235c7df262264e77ce62622f32725eb0424", "daisy",
  3,
  {"17791536...", "anteater", 2,
   {"2fc521ec...", "aardvark", 1, {"cf9c1cb8...", "aardvark", 0, nil, nil},
    {"b0ce2ef9...", "anteater", 0, nil, nil}},
   {"42029ef2...", "daisy", 0, nil, nil}},
  {"add50264...", "giraffe", 2,
   {"3b002bc0...", "elephant", 1, {"cd08c4c4...", "elephant", 0, nil, nil},
    {"6bb7e067...", "giraffe", 0, nil, nil}},
   {"9b02597c...", "walrus", 1, {"96710146...", "walrus", 0, nil, nil},
    {"676cb750...", "zebra", 0, nil, nil}}}}}>
```

```elixir
                   d
              /         \
            a             g
          /   \        /      \
       aa     daisy   e          w
      / \           /  \        / \
aardvark ant elephant giraffe walr zebra
```

* Delete key

```elixir
iex> {:ok, m4} = Merkel.delete(m3, "daisy")
#Merkel.Tree<{6,
  {"9820eab565a08738588256687c806fa2df46b094f2eb8565568d573447361c0a",
   "anteater", 3,
   {"2fc5...", "aardvark", 1, {"cf9c...", "aardvark", 0, nil, nil},
    {"b0ce...", "anteater", 0, nil, nil}},
   {"add5...", "giraffe", 2,
    {"3b00...", "elephant", 1, {"cd08...", "elephant", 0, nil, nil},
     {"6bb7...", "giraffe", 0, nil, nil}},
    {"9b02...", "walrus", 1, {"9671...", "walrus", 0, nil, nil},
     {"676c...", "zebra", 0, nil, nil}}}}}>
```

```elixir
                   a
              /         \
            aa             g
          /   \        /      \
  aardvark   ant      e          w
                    /  \        / \
             elephant giraffe walr zebra
```

* Insert key value

```elixir
iex> m5 = Merkel.insert(m4, {"penguin", :waddle})
#Merkel.Tree<{7,
 {"e79f6fa607ad5d0a8e93a8ba759b266d52a71471222f11fe1ab07ee89ef9f4a4", "giraffe",
  3,
  {"3c2f...", "anteater", 2,
   {"2fc5...", "aardvark", 1, {"cf9c...", "aardvark", 0, nil, nil},
    {"b0ce...", "anteater", 0, nil, nil}},
   {"3b00...", "elephant", 1, {"cd08...", "elephant", 0, nil, nil},
    {"6bb7...", "giraffe", 0, nil, nil}}},
  {"0d77...", "walrus", 2,
   {"b881...", "penguin", 1, {"0a43...", "penguin", 0, nil, nil},
    {"9671...", "walrus", 0, nil, nil}}, {"676c...", "zebra", 0, nil, nil}}}}>
```

```elixir
                       g
              /               \
            a                     w
          /   \                /      \
       aa       e             p          zebra
      / \      / \           /  \       
aardvark ant elep giraffe  penguin walrus
```

* Update value for key

```elixir
iex> m6 = Merkel.insert(m5, {"walrus", {"eats too many fish"}})
...(same as above)...
iex> Merkel.lookup(m6, "walrus")
{:ok, {"eats too many fish"}}
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
---- denotes sibling audit hashes

w inner -> 0d77..
aa inner -> 2fc5..
giraffe -> 6bb7..

                       g
              /               \
            a                     w
                                -----
          /   \                /      \
       aa       e             p          zebra
      ----
      / \      / \           /  \       
aardvark ant elep giraffe  penguin walrus
             ==== -------
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