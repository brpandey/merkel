defmodule Merkel.CryptoTest do
  use ExUnit.Case, async: true


  # https://bitcoin.stackexchange.com/questions/5671/how-do-you-perform-double-sha-256-encoding

  test "single hashing" do

    hello_hash = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

    assert hello_hash == Merkel.Crypto.hash("hello")
    assert hello_hash == Merkel.Crypto.hash("hello", :sha256)
    assert hello_hash == Merkel.Crypto.hash("hello", :sha256, :single)
  end


  test "double hashing" do

    # Double hashing means we hash the binary twice 
    # not the hex or base16 version 

    # (We later convert it to hex)

    hello_hash_bin1 = :crypto.hash(:sha256, "hello")
    hello_hash_bin2 = :crypto.hash(:sha256, hello_hash_bin1)

    hello_hash_hex2 = hello_hash_bin2 |> Base.encode16(case: :lower)

    assert hello_hash_hex2 == Merkel.Crypto.hash("hello", :sha256, :double)
  end




end
