defmodule ElasticAPM.Application do
  use Application
  
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(ElasticAPM.Agent, [])
    ]
    opts = [strategy: :one_for_all, name: ElasticAPM.Supervisor]
    Supervisor.start_link(children, opts)
  end

end