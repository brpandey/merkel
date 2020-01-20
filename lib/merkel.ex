defmodule Merkel do
  @moduledoc """
  Essentially a driver module but allows for the 
  decoupled addition of e.g. new tree types and/or other proof types.
  """

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.{Audit, Printer}

  # Merkle tree CRUD
  @spec new(none | list(tuple)) :: Tree.t()
  def new(), do: Tree.create()
  def new(list) when is_list(list), do: Tree.create(list)

  @spec lookup(Tree.t(), Tree.key()) :: tuple
  def lookup(%Tree{} = t, key) when is_binary(key), do: Tree.lookup(t, key)

  @spec keys(Tree.t()) :: list
  def keys(%Tree{} = t), do: Tree.keys(t)

  @spec values(Tree.t()) :: list
  def values(%Tree{} = t), do: Tree.values(t)

  @spec to_list(Tree.t()) :: list
  def to_list(%Tree{} = t), do: Tree.to_list(t)

  @spec insert(Tree.t(), Tree.pair()) :: Tree.t()
  def insert(%Tree{} = t, {k, v}) when is_binary(k), do: Tree.insert(t, {k, v})

  @spec delete(Tree.t(), Tree.key()) :: Tree.t()
  def delete(%Tree{} = t, key) when is_binary(key), do: Tree.delete(t, key)

  # Proof and verification
  @spec audit(Tree.t(), Tree.key()) :: Audit.t()
  def audit(%Tree{} = t, key) when is_binary(key), do: Audit.create(t, key)

  @spec verify(Audit.t(), String.t()) :: boolean
  def verify(%Audit{} = proof, root_hash) do
    Audit.verify(proof, root_hash)
  end

  # Helpers
  @spec tree_hash(Tree.t()) :: String.t()
  def tree_hash(%Tree{} = t), do: Tree.tree_hash(t)

  @spec size(Tree.t()) :: non_neg_integer
  def size(%Tree{} = t), do: Tree.size(t)

  @spec print(Tree.t()) :: :ok
  def print(%Tree{} = t), do: Printer.pretty_print(t)

  @spec dump(Tree.t()) :: binary
  def dump(%Tree{} = t), do: Tree.dump(t)

  @spec store(Tree.t(), binary) :: :ok | no_return()
  def store(%Tree{} = t, path) when is_binary(path), do: Tree.store(t, path)
end
