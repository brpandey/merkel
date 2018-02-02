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
  @spec hash(binary, atom, atom) :: String.t()
  def hash(bin, type \\ @hash_type, apply \\ @hash_apply) when is_binary(bin) do
    # If not valid hash_algorithm or not provided use the default
    case type do
      t when t in @hash_algorithms ->
        hash1(bin, t, apply)

      # default case
      _ ->
        hash1(bin, @default_hash, apply)
    end
  end

  # Public helper routine to hash with no arg defaults
  @spec hash1(binary, atom, atom) :: String.t()
  def hash1(bin, type, apply)
      when is_binary(bin) and is_atom(type) and is_atom(apply) do
    case apply do
      :double ->
        :crypto.hash(type, :crypto.hash(type, bin))
        |> Base.encode16(case: :lower)

      # default is hash once
      _ ->
        :crypto.hash(type, bin) |> Base.encode16(case: :lower)
    end
  end

  # Public helper routine to concat hashes takes hash strings or Nodes as args
  @spec hash_concat(binary | Node.t(), binary | Node.t()) :: String.t()
  def hash_concat(lh, rh) when is_binary(lh) and is_binary(rh), do: hash(lh <> rh)
  def hash_concat(%Node{} = l, %Node{} = r), do: hash(l.key_hash <> r.key_hash)
end
