defmodule ElasticAPM.Database.EctoLogger do
  def log(value, metadata) do
    IO.inspect(value)
    IO.inspect(metadata)
  end
end