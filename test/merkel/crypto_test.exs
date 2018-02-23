defmodule Merkel.CryptoTest do
  use ExUnit.Case, async: true

  @hello_hash "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
  @hello_double_hash "9595c9df90075148eb06860365df33584b75bff782a510c6cd4883a419833d50"

  # https://bitcoin.stackexchange.com/questions/5671/how-do-you-perform-double-sha-256-encoding

  test "default hash" do
    assert @hello_hash == Merkel.Crypto.hash("hello")
    assert @hello_hash == Merkel.Crypto.hash("hello", nil)
    assert @hello_hash == Merkel.Crypto.hash("hello", :kx999)
    assert @hello_hash == Merkel.Crypto.hash("hello", :sha256)
    assert @hello_hash == Merkel.Crypto.hash("hello", :sha256, &:crypto.hash/2)
  end

  test "correct user supplied hash function" do
    # NOTE: When supplying in config file, must use the &Mod.fun/arity format
    # The anonymous function here won't work via the config file

    lambda = &(:crypto.hash(:sha384, &1) |> Base.encode16(case: :lower))

    hello_hash = lambda.("hello")

    assert hello_hash == Merkel.Crypto.hash("hello", nil, lambda)
  end

  test "incorrect arity user supplied hash function" do
    lambda = &(:crypto.hash(&1, &2) |> Base.encode16(case: :lower))

    error = %ArgumentError{
      message:
        "Please ensure hash function passed in has arity 1, accepting a binary and then returning a binary."
    }

    assert @hello_hash == Merkel.Crypto.hash("hello")
    assert catch_error(Merkel.Crypto.hash("hello", nil, lambda)) == error
  end

  test "incorrect type user supplied hash function" do
    # lambda1 has wrong output type (and makes a lousy hash function)
    lambda1 = &String.to_integer(&1)

    # lambda2 has wrong input and output type 
    lambda2 = &Kernel.round(&1)

    error = %ArgumentError{
      message:
        "Please ensure hash function passed in has arity 1, accepting a binary and then returning a binary."
    }

    assert @hello_hash == Merkel.Crypto.hash("hello")
    assert catch_error(Merkel.Crypto.hash("hello", nil, lambda1)) == error
    assert catch_error(Merkel.Crypto.hash("hello", nil, lambda2)) == error
  end

  test "double hashing" do
    # Double hashing means we hash the binary twice 
    # not the hex or base16 version 

    # (We later convert it to hex)

    hello_hash_bin1 = :crypto.hash(:sha256, "hello")
    hello_hash_bin2 = :crypto.hash(:sha256, hello_hash_bin1)

    hello_hash_hex2 = hello_hash_bin2 |> Base.encode16(case: :lower)

    assert hello_hash_hex2 == Merkel.Crypto.hash("hello", :sha256_sha256)
    assert @hello_double_hash == hello_hash_hex2
  end
end
