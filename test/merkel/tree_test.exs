defmodule Merkel.TreeTest do
  use ExUnit.Case, async: true

  # Test tree create, lookup, keys, insert, delete operations


  import Merkel.Helper

  # Would like to use quick check or some property testing
  # But will do it old fashioned way to build intuition first
  # Plus its fun drawing

  # nil

  describe "empty tree" do

    test "create tree" do

    end

    test "lookup item" do

    end

    test "keys tree" do

    end

    test "insert item" do

    end

    test "delete item" do

    end

    test "size tree" do

    end

    test "root hash" do

    end

  end


  # root

  describe "tree of size 1" do


  end

  # root 
  #  / \
  # l   r

  describe "tree of size 2" do

  end

  # 1) false, _               2) true, _             
  #       root                 root
  #      /    \               /    \
  #  inner     r             l      inner
  #  / \                            /    \
  # l   r                          l      r

  describe "tree of size 3" do


  end

  #        root
  #       /     \
  #  inner       inner
  #  /    \      /    \
  # l     r     l      r

  describe "tree of size 4" do

  end

  # 1) false, false
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #   inner   r  l       r
  #   /   \
  #  l     r

  # 2) false, true
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #    l    inner l       r
  #         /   \
  #        l     r

  # 3) true, false
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #    l      r  l      inner
  #                     /   \
  #                    l     r

  # 4) true, true
  #
  #           root              
  #          /    \
  #      inner     inner
  #     /    \    /     \
  #    l      r inner    r
  #             /   \
  #            l     r

  describe "tree of size 5" do

  end


end
