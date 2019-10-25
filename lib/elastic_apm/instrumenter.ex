defmodule ElasticAPM.Instrumenter do
  defmacro __using__(_arg) do
    quote do 
      plug(ElasticAPM.Plugs.ControllerPlug)
    end
  end
end