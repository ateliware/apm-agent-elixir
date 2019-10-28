defmodule ElasticAPM.TrackedRequestTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias ElasticAPM.TrackedRequest

  setup do
    ElasticAPM.TestCollector.clear_messages()
    :ok
  end

  describe "new/0" do
    test "creates a TrackedRequest" do
      assert ElasticAPM.TrackedRequest == TrackedRequest.new().__struct__
    end

    test "accepts a function as an argument" do
      assert ElasticAPM.TrackedRequest == TrackedRequest.new(fn r -> r end).__struct__
    end
  end

  test "starting a layer, then stopping calls the track function" do
    pid = self()

    TrackedRequest.new(fn r ->
      ElasticAPM.Command.Batch.from_tracked_request(r)
      |> ElasticAPM.Command.message()

      send(pid, {:complete, r})
    end)
    |> TrackedRequest.start_layer("foo", "bar", [])
    |> TrackedRequest.stop_layer()

    receive do
      {:complete, r} ->
        assert ElasticAPM.TrackedRequest == r.__struct__

      _ ->
        refute true, "Unexpected message"
    after
      1000 ->
        refute true, "Timed out message"
    end
  end

  test "the root layer is whichever layer was started first" do
    pid = self()

    TrackedRequest.new(fn r -> send(pid, {:complete, r}) end)
    |> TrackedRequest.start_layer("foo", "bar", [])
    |> TrackedRequest.start_layer("nested", "x", [])
    |> TrackedRequest.stop_layer()
    |> TrackedRequest.stop_layer()

    receive do
      {:complete, r} ->
        assert r.root_layer.type == "foo"
        assert r.root_layer.name == "bar"

      _ ->
        refute true, "Unexpected message"
    after
      1000 ->
        refute true, "Timed out message"
    end
  end

  test "children get attached correctly" do
    pid = self()

    TrackedRequest.new(fn r -> send(pid, {:complete, r}) end)
    |> TrackedRequest.start_layer("foo", "bar", [])
    |> TrackedRequest.start_layer("nested", "x1", [])
    |> TrackedRequest.start_layer("nested2", "y", [])
    |> TrackedRequest.stop_layer()
    |> TrackedRequest.stop_layer()
    |> TrackedRequest.start_layer("nested", "x2", [])
    |> TrackedRequest.stop_layer()
    |> TrackedRequest.stop_layer()

    receive do
      {:complete, r} ->
        assert [c1, c2] = r.root_layer.children
        assert c1.name == "x1"
        assert c2.name == "x2"
        assert List.first(c1.children).name == "y"

      _ ->
        refute true, "Unexpected message"
    after
      1000 ->
        refute true, "Timed out message"
    end
  end

  test "Starting a layer w/o an explicit record saves it in the process dictionary" do
    TrackedRequest.start_layer("foo", "bar")
    assert ElasticAPM.TrackedRequest == Process.get(:elastic_apm_request).__struct__
  end

  test "Correctly discards and logs warning when layer is not stopped" do
    Mix.Config.persist(elastic_apm: [monitor: true, key: "abc123"])
    pid = self()

    assert capture_log(fn ->
             TrackedRequest.new(fn r -> send(pid, {:complete, r}) end)
             |> TrackedRequest.stop_layer()
           end) =~ "Scout Layer mismatch"

    Application.delete_env(:elastic_apm, :monitor)
    Application.delete_env(:elastic_apm, :key)
  end

  test "rename creates a TagRequest" do
    TrackedRequest.start_layer("foo", "bar", [])
    TrackedRequest.start_layer("nested", "x", [])
    TrackedRequest.stop_layer()
    TrackedRequest.rename("testing-rename")
    TrackedRequest.stop_layer()

    [%{BatchCommand: %{commands: commands}}] = ElasticAPM.TestCollector.messages()

    assert Enum.any?(commands, fn command ->
             map = Map.get(command, :TagRequest)

             map && Map.get(map, :tag) == "transaction.name" &&
               Map.get(map, :value) == "testing-rename"
           end)
  end
end
