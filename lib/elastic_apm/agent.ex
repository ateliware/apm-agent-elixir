defmodule ElasticAPM.Agent do
  use GenServer
  
  def start_link(module) do
    options = []
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl GenServer
  def init(module) do
    start()
  end

  def start() do
    require IEx; IEx.pry()
    GenServer.cast(__MODULE__, :setup)
  end

  @impl GenServer
  def handle_cast(:setup, state) do
    require IEx; IEx.pry()
    #TODO create the setup function like ruby agent.
    initialize()
  end

  @impl GenServer
  def handle_call(:send, _from, state) do
  end

  def initialize do
   # Set const configs.
  end
end