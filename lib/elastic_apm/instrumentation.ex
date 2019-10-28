defmodule ElasticAPM.Instrumentation do
  defmacro __using__(_arg) do
    quote do
      plug(ElasticAPM.DevTrace.Plug)
      plug(ElasticAPM.Plugs.ControllerTimer)
    end
  end
end
