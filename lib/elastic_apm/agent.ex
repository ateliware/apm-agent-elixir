defmodule ElasticAPM.Agent do
  use GenServer
  
  defstruct[:configs]

  def start_link() do
    options = []
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl GenServer
  def init(state) do
    start()
    {:ok, state}
  end

  def start() do
    GenServer.cast(__MODULE__, :setup)
  end

  @impl GenServer
  def handle_cast(:setup, state) do
    {:noreply, %{state | configs: setup()}}
  end

  def setup do
    #TODO create the setup function like ruby agent.
   %{
      any: "some text"
    }
  end
end