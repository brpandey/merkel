defmodule Merkel do

  def new(list) when is_list(list) do
    Merkel.BinaryHashTree.create(list)
  end

end
