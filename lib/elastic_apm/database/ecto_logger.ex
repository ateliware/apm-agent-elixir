defmodule ElasticAPM.Database.EctoLogger do
  def log(value, metadata) do
    require IEx; IEx.pry()
    IO.inspect(value)
  end
end