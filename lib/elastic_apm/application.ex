defmodule ElasticApm.Application do
  use Application
  
  def start(_fitas, _args) do
    children = []
    opts = [strategy: :one_for_all, name: ElasticApm.Supervisor]
    Supervisor.start_link(children, opts)
  end

end