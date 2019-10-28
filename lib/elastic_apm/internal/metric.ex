defmodule ElasticAPM.Internal.Metric do
  @moduledoc """
  Store a single metric, that may contain aggregated data around many calls to that metric.
  Uniquely identified by type / name / desc / scope
  """

  alias ElasticAPM.Internal.Layer
  alias ElasticAPM.Internal.Duration

  @type t :: %__MODULE__{
          type: String.t(),
          name: String.t(),
          scope: nil | %{},
          call_count: non_neg_integer(),
          desc: nil | String.t(),
          total_time: Duration.t(),
          exclusive_time: Duration.t(),
          min_time: Duration.t(),
          max_time: Duration.t(),
          backtrace: nil | list(any())
        }

  defstruct [
    :type,
    :name,

    # scope should be a
    :scope,
    :call_count,
    :desc,

    # If call count is > 1, the times should be the sum.
    :total_time,
    :exclusive_time,
    :min_time,
    :max_time,
    :backtrace
  ]

  ##################
  #  Construction  #
  ##################

  @spec from_layer_as_summary(Layer.t()) :: t
  def from_layer_as_summary(%Layer{} = layer) do
    total_time = Layer.total_time(layer)

    %__MODULE__{
      type: layer.type,
      # The magic string, expected by APM server.
      name: "all",
      desc: nil,
      scope: nil,
      call_count: 1,
      total_time: total_time,
      exclusive_time: Layer.total_exclusive_time(layer),
      min_time: total_time,
      max_time: total_time,
      backtrace: nil
    }
  end

  # Layers don't know their own scope, so you need to pass it in explicitly.
  @spec from_layer(Layer.t(), nil | map()) :: t
  def from_layer(%Layer{} = layer, scope) do
    total_time = Layer.total_time(layer)

    %__MODULE__{
      type: layer.type,
      name: layer.name,
      desc: layer.desc,
      scope: scope,
      call_count: 1,
      total_time: total_time,
      exclusive_time: Layer.total_exclusive_time(layer),
      min_time: total_time,
      max_time: total_time,
      backtrace: layer.backtrace
    }
  end

  # Creates a metric with +type+, +name+, and +number+. +number+ is reported as-is in the payload w/o any unit conversion.
  @spec from_sampler_value(any, any, number()) :: t
  def from_sampler_value(type, name, number) do
    # ensures +number+ is reported as-is.
    duration = ElasticAPM.Internal.Duration.new(number, :seconds)

    %__MODULE__{
      type: type,
      name: name,
      call_count: 1,
      total_time: duration,
      exclusive_time: duration,
      min_time: duration,
      max_time: duration
    }
  end

  #######################
  #  Updater Functions  #
  #######################

  @spec merge(t, t) :: t
  def merge(%__MODULE__{} = m1, %__MODULE__{} = m2) do
    %__MODULE__{
      type: m1.type,
      name: m1.name,
      desc: m1.desc,
      scope: m1.scope,
      backtrace: m1.backtrace,
      call_count: m1.call_count + m2.call_count,
      total_time: Duration.add(m1.total_time, m2.total_time),
      exclusive_time: Duration.add(m1.exclusive_time, m2.exclusive_time),
      min_time: Duration.min(m1.min_time, m2.min_time),
      max_time: Duration.max(m1.max_time, m2.max_time)
    }
  end

  #############
  #  Queries  #
  #############
end
