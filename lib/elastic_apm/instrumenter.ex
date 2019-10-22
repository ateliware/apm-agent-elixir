defmodule ElasticApm.Instrumenter do
  defmacro __using__(_arg) do
    quote do 
      plug(ElasticApm)
    end
  end
end