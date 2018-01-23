Merkel
==========

![Logo](https://raw.githubusercontent.com/brpandey/merkel/master/priv/images/merkel.png)


Implements a no-frills merkle binary hash tree. [Wikipedia](https://en.wikipedia.org/wiki/Merkle_tree)

This library is named in honor of Angela Merkel and to salute her desire to make 
important algorithms more transparent.

Merkle trees are a beautiful data structure named in honor of distinguished computer scientist Ralph Merkle.


> Merkel Urges Transparency For Internet Giants’ Algorithms
>
> Angela Merkel has called on the big internet giants to be more transparent 
> in how their algorithms for prioritising news material work in order 
> to avoid narrowing the breadth of information available to consumers.
>
> “I am of the opinion that algorithms must be made more transparent so that one 
> can inform oneself as an interested citizen about questions like, ‘What influences my 
> behaviour on the internet and that of others?’” 
>
> “These algorithms — when they are not transparent — can lead to a distortion of our perception. 
> They narrow our breadth of information.”
>
> “The chancellor certainly does not mean that the companies should reveal their business secrets,” 
> Thomas Jarzombek, ...
> “But we need more information from operators like Facebook about how their algorithm really works.”
> 
> [Source](http://www.newsmediauk.org/Latest/merkel-calls-for-transparency-of-internet-giants-algorithms)

## Noteworthy

To be added...


## Usage

* Helpful background

```elixir
iex> Enum.map(~w(xylophone yellow zebra 42), &Merkel.BinaryHashTree.hash/1) |> Enum.with_index
[{"ee726105e930b4a502901f9a725b1dac59aab4cfad6a568032a8606c4d6d336e", 0},
 {"c685a2c9bab235ccdd2ab0ea92281a521c8aaf37895493d080070ea00fc7f5d7", 1},
 {"676cb75018edccf10fce6f376f2124e02c3293fa3fe8f953c75386198c714514", 2},
 {"73475cb40a568e8da8a045ced110137e159f890ac4da883b6b17dc651b3a8049", 3}]
```

* Create new MHT

```elixir
iex>  m = Merkel.new(~w(xylophone yellow zebra 42))                          

#Merkel.Tree<{4,
 {"6e320984...", 2,
  {"c86d8a28...", 1, {"ee726105...", 0, nil, nil},
   {"c685a2c9...", 0, nil, nil}},
  {"248a11bd...", 1, {"676cb750...", 0, nil, nil},
   {"73475cb4...", 0, nil, nil}}}}>

```

* Create audit proof

```elixir
iex> proof = Merkel.Proof.Audit.create(m, {:data, "zebra"})
%Merkel.Proof.Audit{index: 2,
 key: "676cb75018edccf10fce6f376f2124e02c3293fa3fe8f953c75386198c714514",
 path: ["73475cb40a568e8da8a045ced110137e159f890ac4da883b6b17dc651b3a8049",
  "c86d8a28994b09631b8b6fbf80806b573f6461f4831e6cdce05cca3672beeed3"],
 tree_hash: "6e320984e8fa76c079fdfcad24bb106fdb7abe85462c769e726e7c2369b49077"}

```

* Verify audit proof

```elixir
iex> Merkel.Proof.Audit.verify(proof)
true
```