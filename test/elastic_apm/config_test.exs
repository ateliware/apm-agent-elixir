defmodule ElasticAPM.ConfigTest do
  use ExUnit.Case, async: false

  test "find/1 with plain value" do
    Mix.Config.persist(elastic_apm: [key: "abc123"])

    key = ElasticAPM.Config.find(:key)

    assert key == "abc123"
    Application.delete_env(:elastic_apm, :key)
  end

  test "find/1 with application defined ENV variable" do
    System.put_env("APM_API_KEY", "xyz123")
    Mix.Config.persist(elastic_apm: [key: {:system, "APM_API_KEY"}])

    key = ElasticAPM.Config.find(:key)
    System.delete_env("APM_API_KEY")

    assert key == "xyz123"
  end

  test "find/1 with SCOUT_* ENV variables" do
    System.put_env("SCOUT_KEY", "zxc")
    key = ElasticAPM.Config.find(:key)
    assert key == "zxc"
    System.delete_env("SCOUT_KEY")
  end
end
