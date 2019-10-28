defmodule ElasticAPM.Payload.SlowTransaction do
  @moduledoc """
  The payload structure for a single SlowTransaction / Trace.
  """

  alias ElasticAPM.Internal.WebTrace
  alias ElasticAPM.Internal.Duration

  defstruct [
    :key,
    :time,
    :metrics,
    :allocation_metrics,
    :total_call_time,
    :uri,
    :context,
    :score,
    :mem_delta,
    :allocations,
    :seconds_since_startup,
    :hostname,
    :git_sha,
    :truncated_metrics
  ]

  def new(%WebTrace{} = trace) do
    %__MODULE__{
      key: %{
        bucket: trace.type,
        name: trace.name
      },
      context: ElasticAPM.Payload.Context.new(trace.contexts),
      time: trace.time,
      total_call_time: Duration.as(trace.total_call_time, :seconds),
      uri: trace.uri,
      metrics: trace.metrics |> Enum.map(fn m -> ElasticAPM.Payload.Metric.new(m) end),
      score: trace.score,
      mem_delta: 0,
      allocation_metrics: %{},
      allocations: 0,
      seconds_since_startup: 0,
      hostname: trace.hostname,
      git_sha: trace.git_sha,
      truncated_metrics: %{}
    }
  end
end
