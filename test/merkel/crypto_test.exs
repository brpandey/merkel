defmodule Merkel.CryptoTest do
  use ExUnit.Case, async: true

  @hello_hash "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

  # https://bitcoin.stackexchange.com/questions/5671/how-do-you-perform-double-sha-256-encoding

  test "default hash function" do
    assert @hello_hash == Merkel.Crypto.hash("hello")
    assert @hello_hash == Merkel.Crypto.hash("hello", :sha256, &:crypto.hash/2)
  end

  test "correct user supplied hash function" do
    lambda = &(:crypto.hash(:sha256, &1) |> Base.encode16(case: :lower))

    assert @hello_hash == Merkel.Crypto.hash("hello")
    assert @hello_hash == Merkel.Crypto.hash("hello", nil, lambda)
  end

  test "incorrect user supplied hash function" do
    lambda = &(:crypto.hash(&1, &2) |> Base.encode16(case: :lower))

    error = %ArgumentError{
      message:
        "Please ensure hash function passed in has arity 1, accepting a single binary argument."
    }

    assert @hello_hash == Merkel.Crypto.hash("hello")
    assert catch_error(Merkel.Crypto.hash("hello", nil, lambda)) == error
  end

  test "double hashing" do
    # Double hashing means we hash the binary twice 
    # not the hex or base16 version 

    # (We later convert it to hex)

    hello_hash_bin1 = :crypto.hash(:sha256, "hello")
    hello_hash_bin2 = :crypto.hash(:sha256, hello_hash_bin1)

    hello_hash_hex2 = hello_hash_bin2 |> Base.encode16(case: :lower)

    assert hello_hash_hex2 == Merkel.Crypto.hash("hello", :sha256_sha256)
  end
end
