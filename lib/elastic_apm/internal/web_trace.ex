defmodule ElasticAPM.Internal.WebTrace do
  @moduledoc """
  A record of a single trace.
  """

  alias ElasticAPM.MetricSet
  alias ElasticAPM.Internal.Duration
  alias ElasticAPM.Internal.Metric
  alias ElasticAPM.Internal.Layer
  alias ElasticAPM.Internal.Context
  alias ElasticAPM.ScopeStack

  defstruct [
    :type,
    :name,
    :total_call_time,
    :metrics,
    :uri,
    :time,
    :hostname,
    :git_sha,
    :contexts,

    # TODO: Does anybody ever set this Score field?
    :score
  ]

  @type t :: %__MODULE__{
          type: String.t(),
          name: String.t(),
          total_call_time: Duration.t(),
          metrics: list(Metric.t()),
          uri: nil | String.t(),
          time: any,
          hostname: String.t(),
          git_sha: String.t(),
          contexts: Context.t(),
          score: number()
        }

  # @spec new(String.t, String.t, Duration.t, list(Metric.t), String.t, Context.t, any, String.t, String.t | nil) :: t
  def new(type, name, duration, metrics, uri, contexts, time, hostname, git_sha) do
    %__MODULE__{
      type: type,
      name: name,
      total_call_time: duration,
      metrics: metrics,
      uri: uri,
      time: time,
      hostname: hostname,
      git_sha: git_sha,
      contexts: contexts,

      # TODO: Store the trace's own score
      score: 0
    }
  end

  # Creates a Trace struct from a `TracedRequest`.
  def from_tracked_request(tracked_request) do
    root_layer = tracked_request.root_layer

    duration = Layer.total_time(root_layer)

    uri = root_layer.uri

    contexts = tracked_request.contexts

    time = DateTime.utc_now() |> DateTime.to_iso8601()
    hostname = ElasticAPM.Cache.hostname()
    git_sha = ElasticAPM.Cache.git_sha()

    # Metrics scoped & stuff. Distinguished by type, name, scope, desc
    metric_set =
      create_trace_metrics(
        root_layer,
        ScopeStack.new(),
        MetricSet.new(%{compare_desc: true, collapse_all: true})
      )

    new(
      root_layer.type,
      root_layer.name,
      duration,
      MetricSet.to_list(metric_set),
      uri,
      contexts,
      time,
      hostname,
      git_sha
    )
  end

  # Each layer creates two Trace metrics:
  # - a detailed one distinguished by type/name/scope/desc
  # - a summary one distinguished only by type
  #
  # TODO:
  #   Layers inside of Layers isn't scoped fully here. The recursive call
  #   should figure out if we need to update the scope we're passing down the
  #   tree.
  #
  #   In ruby land, that would be a situation like:
  #   Controller
  #     DB         <-- scoped under controller
  #     View
  #       DB       <-- scoped under View
  defp create_trace_metrics(layer, scope_stack, %MetricSet{} = metric_set) do
    detail_metric = Metric.from_layer(layer, ScopeStack.current_scope(scope_stack))
    summary_metric = Metric.from_layer_as_summary(layer)

    new_scope_stack = ScopeStack.push_scope(scope_stack, layer)

    # Absorb each child recursively
    Enum.reduce(layer.children, metric_set, fn child, set ->
      create_trace_metrics(child, new_scope_stack, set)
    end)
    # Then absorb this layer's 2 metrics
    |> MetricSet.absorb(detail_metric)
    |> MetricSet.absorb(summary_metric)
  end

  #####################
  #  Scoring a trace  #
  #####################

  @point_multiplier_speed 0.25
  @point_multiplier_percentile 1.0

  defp key(%__MODULE__{} = trace) do
    trace.type <> "/" <> trace.name
  end

  def as_scored_item(%__MODULE__{} = trace) do
    {{:score, score(trace), key(trace)}, trace}
  end

  def score(%__MODULE__{} = trace) do
    duration_score(trace) + percentile_score(trace)
  end

  defp duration_score(%__MODULE__{} = trace) do
    :math.log(1 + Duration.as(trace.total_call_time, :seconds)) * @point_multiplier_speed
  end

  defp percentile_score(%__MODULE__{} = trace) do
    with {:ok, percentile} <-
           ElasticAPM.PersistentHistogram.percentile_for_value(
             key(trace),
             Duration.as(trace.total_call_time, :seconds)
           ) do
      raw =
        cond do
          # Don't put much emphasis on capturing low percentiles.
          percentile < 40 ->
            0.4

          # Higher here to get more "normal" mean traces
          percentile < 60 ->
            1.4

          # Between 60 & 90% is fine.
          percentile < 90 ->
            0.7

          # Highest here to get 90+%ile traces
          percentile >= 90 ->
            1.8
        end

      raw * @point_multiplier_percentile
    else
      # If we failed to lookup the percentile, just give back a 0 score.
      err ->
        ElasticAPM.Logger.log(:debug, "Failed to get percentile_score, error: #{err}")
        0
    end
  end
end
