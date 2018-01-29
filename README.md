Merkel
==========
![Logo](https://raw.githubusercontent.com/brpandey/merkel/master/priv/images/merkel.png)

Implements a dynamic, merkle binary hash tree. [Wikipedia](https://en.wikipedia.org/wiki/Merkle_tree), [Bitcoin](http://chimera.labs.oreilly.com/books/1234000001802/ch07.html#merkle_trees)

Merkle trees are a beautiful data structure for summarizing and verifying data integrity.
They are named in honor of distinguished computer scientist Ralph Merkle, while this library is named
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
iex> m = Merkel.new(l)                                                                              
 {"f92f0f98d165457a4122bbe165aefa14928f45943f9b11880b51d720a1ad37c1", "giraffe",
  3,
  {"bbe4b971...", "daisy", 2,
   {"5ad27451...", "anteater", 1, {"b0ce2ef9...", "anteater", 0, nil, nil},
    {"42029ef2...", "daisy", 0, nil, nil}},
   {"6bb7e067...", "giraffe", 0, nil, nil}},
  {"9b02597c...", "walrus", 1, {"96710146...", "walrus", 0, nil, nil},
   {"676cb750...", "zebra", 0, nil, nil}}}>
```

* Lookup key

```elixir
iex> Merkel.lookup(m, "walrus")
{:ok, 49}
```

* Insert key value pairs (and notice rotations)

```elixir
iex> m = Merkel.insert(m, {"aardvark", 999})
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
iex> m = Merkel.insert(m, {"elephant", "He's big"})
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

* Delete key

```elixir
iex> Merkel.delete(m, "aardvark")
{:ok,
 #Merkel.Tree<{6,
  {"8ed22afe60870ac4f40647dcc8e47b9cba76acdae7dd5cd14419ebe529926b95", "daisy",
   3,
   {"5ad27451...", "anteater", 2, {"b0ce2ef9...", "anteater", 0, nil, nil},
    {"42029ef2...", "daisy", 0, nil, nil}},
   {"add50264...", "giraffe", 2,
    {"3b002bc0...", "elephant", 1, {"cd08c4c4...", "elephant", 0, nil, nil},
     {"6bb7e067...", "giraffe", 0, nil, nil}},
    {"9b02597c...", "walrus", 1, {"96710146...", "walrus", 0, nil, nil},
     {"676cb750...", "zebra", 0, nil, nil}}}}}>}
```

* Create audit proof

```elixir
iex> proof = Merkel.audit(m, "elephant")
%Merkel.Audit{
  key: "elephant",
  path: {"17791536269eca21572c30cd9068bd4549c590eb58b988c1086ae32f43e9afb4",
   {{{}, "6bb7e067447139b18f6094d2d15bcc264affde89a8b9f5227fe5b38abd8b19d7"},
    "9b02597cc10da600d73d06b42e10b5f6dfc2359eb13a282bf9eb8c9f4a45626d"}}
}
```

* Verify audit proof

```elixir
iex> Merkel.verify(proof, Merkel.tree_hash(m))
true
```



* Configure the hash algorithm to override default
* The default is :sha256, but to override specify hash_algorithm in config.exs


```elixir
# Options are: :md5, :ripemd160, :sha, :sha224, :sha256, :sha384, :sha512
config :merkel, hash_algorithm: :sha384
```