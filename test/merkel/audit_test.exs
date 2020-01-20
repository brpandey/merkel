defmodule Merkel.AuditTest do
  use ExUnit.Case, async: true

  import Merkel.Helper
  import Merkel.TestHelper

  alias Merkel.BinaryHashTree, as: Tree

  @list [
    {"zebra", 23},
    {<<9, 9, 2>>, "992"},
    {"giraffe", nil},
    {"anteater", "12"},
    {"walrus", 49},
    {<<23, 1, 0>>, 99},
    {<<100, 2>>, :furry},
    {"lion", "3"},
    {"kangaroo", nil},
    {"cow", 99},
    {"leopard", :fast}
  ]

  setup do
    # Create two balanced trees one dominant left subtree one random
    {size0, r0} = create_tree(@list)
    t0 = %Tree{size: size0, root: r0}

    {size1, r1} = create_toggle_tree(@list)
    t1 = %Tree{size: size1, root: r1}

    thash0 = Merkel.tree_hash(t0)
    thash1 = Merkel.tree_hash(t1)

    [trees: {t0, t1}, hashes: {thash0, thash1}]
  end

  test "candidate key that resides in tree", %{trees: {t0, t1}, hashes: {h0, h1}} do
    proof1 = %Merkel.Audit{
      key: "lion",
      path:
        {"9dd696ea6d27c7a06560d010075074296e60240185007800913447bf493954aa",
         {{"fc17cb10b1c7ab4942764ab8613b21d249a93adfa6b6caa3de877bd8a87a2bfe", {}},
          "9b02597cc10da600d73d06b42e10b5f6dfc2359eb13a282bf9eb8c9f4a45626d"}}
    }

    proof2 = %Merkel.Audit{
      key: <<23, 1, 0>>,
      path:
        {{{{"0caffc21ccbc3e9be468615980935b89d9aeaf22a8f06ff7af4286b35748189d", {}},
           "b0ce2ef96d43c0e0f83d57785f9a87b647065ca75360ca5e9de520e7f690c3f9"},
          "a55b00e1cd67e97fc580c92770f7660f18b5059888e8ea477df412951d3a6ff3"},
         "c19f02e9301b3389655b5ad8dfde2558a0b0033ce06b66e3171695d89e817ccf"}
    }

    # First assert proof from static tree t0
    assert proof1 == Merkel.audit(t0, "lion")
    assert proof2 == Merkel.audit(t0, <<23, 1, 0>>)

    # Proofs from toggle tree
    proof3 = Merkel.audit(t1, "lion")
    proof4 = Merkel.audit(t1, <<23, 1, 0>>)

    # Since these keys reside in the tree verify should be true
    assert true = Merkel.verify(proof1, h0)
    assert true = Merkel.verify(proof2, h0)
    assert true = Merkel.verify(proof3, h1)
    assert true = Merkel.verify(proof4, h1)
  end

  test "candidate key that does NOT reside in tree", %{trees: {t0, t1}, hashes: {h0, h1}} do
    proof1 = %Merkel.Audit{key: "marshmellow", path: nil}
    proof2 = %Merkel.Audit{key: <<88, 1, 10>>, path: nil}

    assert proof1 == Merkel.audit(t0, "marshmellow")
    assert proof2 == Merkel.audit(t1, <<88, 1, 10>>)

    # Since these keys dont reside in the tree verify should be false
    assert false == Merkel.verify(proof1, h0)
    assert false == Merkel.verify(proof2, h1)
  end

  test "verification with tampered proof", %{trees: {t0, _t1}, hashes: {h0, _}} do
    proof1 = %Merkel.Audit{
      key: "lion",
      path:
        {"9dd696ea6d27c7a06560d010075074296e60240185007800913447bf493954aa",
         {{"fc17cb10b1c7ab4942764ab8613b21d249a93adfa6b6caa3de877bd8a87a2bfe", {}},
          "9b02597cc10da600d73d06b42e10b5f6dfc2359eb13a282bf9eb8c9f4a45626d"}}
    }

    tampered_proof1 = %Merkel.Audit{
      # we add Lion instead of lion
      key: "Lion",
      path:
        {"9dd696ea6d27c7a06560d010075074296e60240185007800913447bf493954aa",
         {{"fc17cb10b1c7ab4942764ab8613b21d249a93adfa6b6caa3de877bd8a87a2bfe", {}},
          "9b02597cc10da600d73d06b42e10b5f6dfc2359eb13a282bf9eb8c9f4a45626d"}}
    }

    proof2 = %Merkel.Audit{
      key: <<23, 1, 0>>,
      path:
        {{{{"0caffc21ccbc3e9be468615980935b89d9aeaf22a8f06ff7af4286b35748189d", {}},
           "b0ce2ef96d43c0e0f83d57785f9a87b647065ca75360ca5e9de520e7f690c3f9"},
          "a55b00e1cd67e97fc580c92770f7660f18b5059888e8ea477df412951d3a6ff3"},
         "c19f02e9301b3389655b5ad8dfde2558a0b0033ce06b66e3171695d89e817ccf"}
    }

    # Change the last path last hex value from ccf to cce
    tampered_proof2 = %Merkel.Audit{
      key: <<23, 1, 0>>,
      path:
        {{{{"0caffc21ccbc3e9be468615980935b89d9aeaf22a8f06ff7af4286b35748189d", {}},
           "b0ce2ef96d43c0e0f83d57785f9a87b647065ca75360ca5e9de520e7f690c3f9"},
          "a55b00e1cd67e97fc580c92770f7660f18b5059888e8ea477df412951d3a6ff3"},
         "c19f02e9301b3389655b5ad8dfde2558a0b0033ce06b66e3171695d89e817cce"}
    }

    # Change the order of the audit paths
    tampered_proof3 = %Merkel.Audit{
      key: <<23, 1, 0>>,
      path:
        {{{{"b0ce2ef96d43c0e0f83d57785f9a87b647065ca75360ca5e9de520e7f690c3f9", {}},
           "0caffc21ccbc3e9be468615980935b89d9aeaf22a8f06ff7af4286b35748189d"},
          "a55b00e1cd67e97fc580c92770f7660f18b5059888e8ea477df412951d3a6ff3"},
         "c19f02e9301b3389655b5ad8dfde2558a0b0033ce06b66e3171695d89e817ccf"}
    }

    # First assert proof from static tree t0
    assert proof1 == Merkel.audit(t0, "lion")
    assert proof2 == Merkel.audit(t0, <<23, 1, 0>>)

    assert false == Merkel.verify(tampered_proof1, h0)
    assert false == Merkel.verify(tampered_proof2, h0)
    assert false == Merkel.verify(tampered_proof3, h0)
  end
end
