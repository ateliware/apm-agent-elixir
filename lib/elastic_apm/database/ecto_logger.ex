defmodule ElasticAPM.Database.EctoLogger do
  def log(entry) do
    require IEx; IEx.pry()
    IO.inspect(entry)
  end
end