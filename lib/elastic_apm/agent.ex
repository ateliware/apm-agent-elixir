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
    GenServer.cast(__MODULE__, :setup)
  end

  @impl GenServer
  def handle_cast(:setup, state) do
    require IEx; IEx.pry()
    #TODO create the setup function like ruby agent.
    {:noreply, %{state | configs: setup()}}
  end

  def setup do
   # Set const configs.
   %{
      any: "some text"
   }
  end
end