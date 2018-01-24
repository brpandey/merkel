Merkel
==========
![Logo](https://raw.githubusercontent.com/brpandey/merkel/master/priv/images/merkel.png)

Implements a no-frills merkle binary hash tree. [Wikipedia](https://en.wikipedia.org/wiki/Merkle_tree)

Merkle trees are a beautiful data structure named in honor of distinguished computer scientist Ralph Merkle.

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

To be added...


## Usage

* Helpful background

```elixir
iex> l = [{"zebra", 23}, {"daisy", "932"}, {"giraffe", 29}, {"anteater", "12"}]
iex> Enum.map(l, fn {k, _v} -> k end) |> Enum.map(&Merkel.BinaryHashTree.hash/1) |> Enum.with_index  
[{"676cb75018edccf10fce6f376f2124e02c3293fa3fe8f953c75386198c714514", 0},
 {"42029ef215256f8fa9fedb53542ee6553eef76027b116f8fac5346211b1e473c", 1},
 {"6bb7e067447139b18f6094d2d15bcc264affde89a8b9f5227fe5b38abd8b19d7", 2},
 {"b0ce2ef96d43c0e0f83d57785f9a87b647065ca75360ca5e9de520e7f690c3f9", 3}]
```

* Create new MHT

```elixir
iex> m = Merkel.new(l)                                                                              
#Merkel.Tree<{4,
 {"3d16890c4c0a80a443bfecc1b3c7b0742931bff09ab544b37615ece19a547496", "daisy",
  2,
  {"5ad27451...", "anteater", 1, {"b0ce2ef9...", "anteater", 0, nil, nil},
   {"42029ef2...", "daisy", 0, nil, nil}},
  {"a1ccb5b0...", "giraffe", 1, {"6bb7e067...", "giraffe", 0, nil, nil},
   {"676cb750...", "zebra", 0, nil, nil}}}}>
```

* Create audit proof

```elixir
iex> proof = Merkel.audit(m, "giraffe")
%Merkel.Proof.Audit{key: "giraffe",
 path: {"5ad274513da265aacbc662d6b541e6e3ee5e3bf0522449e2163ac0df73e5b92c",
  {{}, "676cb75018edccf10fce6f376f2124e02c3293fa3fe8f953c75386198c714514"}}}

```

* Verify audit proof

```elixir
iex> Merkel.verify(proof, "3d16890c4c0a80a443bfecc1b3c7b0742931bff09ab544b37615ece19a547496")
true
```