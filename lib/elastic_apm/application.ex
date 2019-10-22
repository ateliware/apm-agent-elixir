defmodule ElasticApm.Application do
  use Application
  
  def start(_type, _args) do
    require IEx; IEx.pry()
    children = []
    opts = [strategy: :one_for_all, name: ElasticApm.Supervisor]
    Supervisor.start_link(children, opts)
  end

end