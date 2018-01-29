defmodule Merkel do

  alias Merkel.BinaryHashTree, as: Tree
  alias Merkel.Audit


  # Merkle tree CRUD
  @spec new(none | list(tuple)) :: Tree.t
  def new() do 
    t = Tree.create()
    IO.inspect "tree is: #{t}"
  end
  def new(list) when is_list(list), do: Tree.create(list)

  @spec tree_hash(Tree.t) :: String.t
  def tree_hash(%Tree{} = t), do: Tree.tree_hash(t)

  @spec lookup(Tree.t, Tree.key) :: tuple
  def lookup(%Tree{} = t, key) when is_binary(key), do: Tree.lookup(t, key)

  @spec keys(Tree.t) :: list
  def keys(%Tree{} = t), do: Tree.keys(t)

  @spec insert(Tree.t, Tree.pair) :: Tree.t
  def insert(%Tree{} = t, {k,v}) when is_binary(k), do: Tree.insert(t, {k,v})

  @spec delete(Tree.t, Tree.key) :: Tree.t
  def delete(%Tree{} = t, key) when is_binary(key), do: Tree.delete(t, key)


  # Proof and verification
  @spec audit(Tree.t, Tree.key) :: Audit.t
  def audit(%Tree{} = t, key) when is_binary(key), do: Audit.create(t, key)

  @spec verify(Audit.t, String.t) :: boolean
  def verify(%Audit{} = proof, root_hash) when is_binary(root_hash) do
    Audit.verify(proof, root_hash)
  end
end
