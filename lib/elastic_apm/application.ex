defmodule ElasticAPM.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    collector_module = ElasticAPM.Config.find(:collector_module)

    children = [
      worker(ElasticAPM.PersistentHistogram, []),
      worker(ElasticAPM.Watcher, [ElasticAPM.PersistentHistogram], id: :histogram_watcher),
      worker(collector_module, [])
    ]

    ElasticAPM.Cache.setup()

    # Stupidly persistent. Really high max restarts for debugging
    # opts = [strategy: :one_for_all, max_restarts: 10000000, max_seconds: 1, name: ElasticAPM.Supervisor]
    opts = [strategy: :one_for_all, name: ElasticAPM.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    ElasticAPM.Watcher.start_link(ElasticAPM.Supervisor)

    ElasticAPM.Logger.log(:info, "ElasticAPM Started")
    {:ok, pid}
  end
end
