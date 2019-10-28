defmodule ElasticAPM.Config.CoercionsTest do
  use ExUnit.Case, async: true
  alias ElasticAPM.Config.Coercions

  test "boolean/1" do
    assert {:ok, true} = Coercions.boolean("t")
    assert {:ok, true} = Coercions.boolean("true")
    assert {:ok, true} = Coercions.boolean("1")
    assert {:ok, true} = Coercions.boolean("True")
    assert {:ok, true} = Coercions.boolean("TruE")
    assert {:ok, true} = Coercions.boolean("T")

    assert {:ok, false} = Coercions.boolean("false")
    assert {:ok, false} = Coercions.boolean("f")
    assert {:ok, false} = Coercions.boolean("0")
    assert {:ok, false} = Coercions.boolean("False")
    assert {:ok, false} = Coercions.boolean("FaLSe")
    assert {:ok, false} = Coercions.boolean("F")

    assert :error = Coercions.boolean("anything else")
    assert :error = Coercions.boolean(20)
  end

  test "json/1" do
    assert {:ok, ["list", "list"]} = Coercions.json(~s/["list", "list"]/)
    assert {:ok, %{"key" => "value"}} = Coercions.json(~s/{"key": "value"}/)
    assert :error = Coercions.json(1)
    assert :error = Coercions.json("notjson")
  end
end
