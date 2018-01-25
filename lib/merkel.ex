defmodule Merkel do

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.Proof.Audit

  def new(list) when is_list(list) do
    Tree.create(list)
  end

  def lookup(%Tree{} = t, key) when is_binary(key) do
    Tree.lookup(t, key)
  end

  def audit(%Tree{} = t, key) when is_binary(key) do
    Audit.create(t, key)
  end

  def verify(%Audit{} = proof, root_hash) when is_binary(root_hash) do
    Audit.verify(proof, root_hash)
  end
end
