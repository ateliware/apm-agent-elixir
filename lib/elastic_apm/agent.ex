defmodule ElasticApm.Agent do
  use GenServer
  
  def start_link() do
  end

  @impl GenServer
  def init() do
    start()
  end

  def start() do
    GenServer.cast(__MODULE__, :setup)
  end

  @impl GenServer
  def handle_cast(:setup, state) do
    #TODO create the setup function like ruby agent.
    initialize()
  end

  @impl GenServer
  def handle_cast(:send, _from, state) do
  end

  def initialize do
   # Set const configs.
  end
end