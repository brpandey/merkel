defmodule Merkel do

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.Audit

  def new(), do: Tree.create()
  def new(list) when is_list(list), do: Tree.create(list)

  def tree_hash(%Tree{} = t), do: Tree.tree_hash(t)

  def lookup(%Tree{} = t, key) when is_binary(key), do: Tree.lookup(t, key)
  def insert(%Tree{} = t, {k,v}) when is_binary(k), do: Tree.insert(t, {k,v})
  def delete(%Tree{} = t, key) when is_binary(key), do: Tree.delete(t, key)

  def audit(%Tree{} = t, key) when is_binary(key), do: Audit.create(t, key)
  def verify(%Audit{} = proof, root_hash) when is_binary(root_hash) do
    Audit.verify(proof, root_hash)
  end
end
