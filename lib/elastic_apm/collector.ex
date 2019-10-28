defmodule ElasticAPM.Collector do
  @callback send(map()) :: :ok
end
