defmodule ElasticAPM.Database.EctoLogger do
  require ElasticAPM.Core.Agent
  
  def log(value, metadata) do
    IO.inspect(value)
    IO.inspect(metadata)
    ElasticAPM.Core.Agent.span(value, metadata)
  end
end