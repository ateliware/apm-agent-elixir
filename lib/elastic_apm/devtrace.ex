defmodule ElasticAPM.DevTrace do
  def enabled? do
    ElasticAPM.Config.find(:dev_trace)
  end
end
