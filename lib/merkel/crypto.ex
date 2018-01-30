defmodule Merkel.Crypto do
  @moduledoc """
  Module to perform merkle tree hashing
  """

  alias Merkel.BinaryNode, as: Node

  @hash_type Application.get_env(:merkel, :hash_algorithm)
  @hash_apply Application.get_env(:merkel, :hash_apply)

  @default_hash :sha256
  @hash_algorithms [:md5, :ripemd160, :sha, :sha224, :sha256, :sha384, :sha512]


  # Public helper routine to hash
  # Takes hash type with default being :sha256,
  # and hash apply whose default is :single
  @spec hash(binary) :: String.t
  def hash(str, type \\ @hash_type, apply \\ @hash_apply) when is_binary(str) do
    # If not valid hash_algorithm or not provided use the default
    case type do
      t when t in @hash_algorithms -> hash1(str, t, apply)
      _ -> hash1(str, @default_hash, apply) # default case
    end
  end


  # Public helper routine to hash with no arg defaults
  @spec hash1(binary, atom, atom) :: String.t
  def hash1(str, type, apply)
  when is_binary(str) and is_atom(type) and is_atom(apply) do
    case apply do
      :double ->
        :crypto.hash(type, :crypto.hash(type, str)) 
        |> Base.encode16(case: :lower)
      _ -> # default is hash once
        :crypto.hash(type, str) |> Base.encode16(case: :lower)
    end
  end


  # Public helper routine to concat hashes takes hash strings or Nodes as args
  @spec hash_concat(binary | Node.t, binary | Node.t) :: String.t
  def hash_concat(lh, rh) when is_binary(lh) and is_binary(rh), do: hash(lh <> rh)
  def hash_concat(%Node{} = l, %Node{} = r), do: hash(l.key_hash <> r.key_hash)

end
