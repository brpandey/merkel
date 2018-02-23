defmodule Merkel.TreeDumpTest do
  use ExUnit.Case, async: true

  # Test tree etf serialization

  alias Merkel.BinaryHashTree, as: Tree

  @path "./merkel239819ce38jsh3.tmp"
  @small_tree Merkel.new([
                {"zebra", 23},
                {"daisy", "932"},
                {"giraffe", nil},
                {"anteater", "12"},
                {"walrus", 49}
              ])

  setup _ctxt do
    # clean up state
    on_exit(fn ->
      File.rm(@path)
    end)

    :ok
  end

  describe "tree etf serialization and deserialization" do
    test "empty tree" do
      # Create empty tree and dump it
      m1 = Merkel.new()
      etf = Merkel.dump(m1)
      :ok = Merkel.store(m1, @path)

      # Create from etf and file path
      m2 = Merkel.new(etf: etf)
      m3 = Merkel.new(path: @path)

      assert %Tree{size: 0, root: nil} == m1
      assert m1 == m2
      assert m1 == m3
    end

    test "invalid merkel etf" do
      etf = [1, 2, 3, 4, 5] |> :erlang.term_to_binary()

      # Create from invalid etf
      assert catch_error(Merkel.new(etf: etf)) == %ArgumentError{
               message: "Erlang Term Format does not contain a well-formed Merkel Tree term"
             }
    end

    test "invalid serialize file path" do
      # Create small tree, dump it and store it
      m1 = @small_tree
      assert catch_error(Merkel.store(m1, 123)) == :function_clause
    end

    test "successful serialize and deserialize" do
      # Create small tree, dump it and store it
      m1 = @small_tree
      etf = Merkel.dump(m1)
      :ok = Merkel.store(m1, @path)

      # Create from etf and file path
      m2 = Merkel.new(etf: etf)
      m3 = Merkel.new(path: @path)

      assert true == File.exists?(@path)

      # Logger.info("m2 is #{inspect(m2)}")

      # Logger.info("m3 is #{inspect(m3)}")

      assert "#Merkel.Tree<{5, {\"f92f0f98d165457a4122bbe165aefa14928f45943f9b11880b51d720a1ad37c1\", \"<=gi..>\", 3, {\"bbe4..\", \"<=da..>\", 2, {\"5ad2..\", \"<=an..>\", 1, {\"b0ce..\", \"anteater\", 0}, {\"4202..\", \"daisy\", 0}}, {\"6bb7..\", \"giraffe\", 0}}, {\"9b02..\", \"<=wa..>\", 1, {\"9671..\", \"walrus\", 0}, {\"676c..\", \"zebra\", 0}}}}>" ==
               "#{inspect(m1)}"

      assert m1 == m2
      assert m1 == m3
    end

    test "unspecified both etf and file path options" do
      # Create small tree, dump it and store it
      m1 = @small_tree
      etf = Merkel.dump(m1)
      :ok = Merkel.store(m1, @path)

      # Create from etf and file path
      m2 = Merkel.new(etfs: etf, pat: @path)

      assert m1 != m2
      assert %Tree{size: 0, root: nil} == m2
    end

    test "specified both etf and file path options" do
      # Create small tree, dump it and store it
      m1 = @small_tree
      etf = Merkel.dump(m1)
      :ok = Merkel.store(m1, @path)

      # Create from etf and file path, should select etf value first
      m2 = Merkel.new(etf: etf, path: :error)

      assert "#Merkel.Tree<{5, {\"f92f0f98d165457a4122bbe165aefa14928f45943f9b11880b51d720a1ad37c1\", \"<=gi..>\", 3, {\"bbe4..\", \"<=da..>\", 2, {\"5ad2..\", \"<=an..>\", 1, {\"b0ce..\", \"anteater\", 0}, {\"4202..\", \"daisy\", 0}}, {\"6bb7..\", \"giraffe\", 0}}, {\"9b02..\", \"<=wa..>\", 1, {\"9671..\", \"walrus\", 0}, {\"676c..\", \"zebra\", 0}}}}>" ==
               "#{inspect(m1)}"

      assert m1 == m2
    end

    test "invalid deserialize file path" do
      # Create small tree and store it
      m1 = @small_tree

      :ok = Merkel.store(m1, @path)

      # Create from etf and invalid file path
      assert catch_error(Merkel.new(path: 123)) == %ArgumentError{
               message: "Unsupported option creation type or value"
             }
    end
  end
end
