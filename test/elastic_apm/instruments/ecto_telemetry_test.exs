defmodule ElasticAPM.Instruments.EctoTelemetryTest do
  use ExUnit.Case, async: true

  describe "attach/1" do
    test "can attach multiple times" do
      assert :ok = ElasticAPM.Instruments.EctoTelemetry.attach(MyApp.RepoA)
      assert :ok = ElasticAPM.Instruments.EctoTelemetry.attach(MyApp.RepoB)
    end
  end
end
