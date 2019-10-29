defmodule ElasticAPM.Core.AgentManager do
  use GenServer
  alias ElasticAPM.Core
  alias ElasticAPM.Core.Manifest
  @behaviour ElasticAPM.Collector

  defstruct [:socket]

  @type t :: %__MODULE__{
          socket: :gen_tcp.socket() | nil
        }

  def start_link() do
    options = []
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  @impl GenServer
  @spec init(any) :: {:ok, t()}
  def init(_) do
    start_setup()
    {:ok, %__MODULE__{socket: nil}}
  end

  def start_setup do
    GenServer.cast(__MODULE__, :setup)
  end

  @spec setup :: :gen_tcp.socket() | nil
  def setup do
    enabled = ElasticAPM.Config.find(:monitor)
    core_agent_launch = ElasticAPM.Config.find(:core_agent_launch)
    key = ElasticAPM.Config.find(:key)

    if enabled && core_agent_launch && key do
      register()
      app_metadata()

      # connection
      # make connection like ruby agent
    else
      nil
    end
  end

  @impl ElasticAPM.Collector
  def send(message) when is_map(message) do
    GenServer.cast(__MODULE__, {:send, message})
  end

  def app_metadata do
    message =
      ElasticAPM.Command.ApplicationEvent.app_metadata()
      |> ElasticAPM.Command.message()

    send(message)
  end

  def register do
    name = ElasticAPM.Config.find(:name)
    key = ElasticAPM.Config.find(:key)
    hostname = ElasticAPM.Config.find(:hostname)

    message =
      ElasticAPM.Command.message(%ElasticAPM.Command.Register{app: name, key: key, host: hostname})

    send(message)
  end

  @impl GenServer
  @spec handle_cast(any, t()) :: {:noreply, t()}
  def handle_cast(:setup, state) do
    {:noreply, %{state | socket: setup()}}
  end

  @impl GenServer
  def handle_cast({:send, _message}, %{socket: nil} = state) do
    ElasticAPM.Logger.log(
      :warn,
      "ElasticAPM Core Agent is not connected. Skipping sending event."
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:send, message}, state) when is_map(message) do
    state = send_message(message, state)
    {:noreply, state}
  end

  @impl GenServer
  @spec handle_call(any, any(), t()) :: {:reply, any, t()}
  def handle_call({:send, _message}, _from, %{socket: nil} = state) do
    ElasticAPM.Logger.log(
      :warn,
      "ElasticAPM Core Agent is not connected. Skipping sending event."
    )

    {:reply, state, state}
  end

  @impl GenServer
  def handle_call({:send, message}, _from, state) when is_map(message) do
    state = send_message(message, state)
    {:reply, state, state}
  end

  @impl GenServer
  @spec handle_info(any, t()) :: {:noreply, t()}
  def handle_info(_m, state) do
    {:noreply, state}
  end

  @spec pad_leading(binary(), integer(), integer()) :: binary()
  def pad_leading(binary, len, byte \\ 0)

  def pad_leading(binary, len, byte)
      when is_binary(binary) and is_integer(len) and is_integer(byte) and len > 0 and
             byte_size(binary) >= len,
      do: binary

  def pad_leading(binary, len, byte)
      when is_binary(binary) and is_integer(len) and is_integer(byte) and len > 0 do
    (<<byte>> |> :binary.copy(len - byte_size(binary))) <> binary
  end

  defp send_message(message, %{socket: socket} = state) do
    with {:ok, encoded} <- Jason.encode(message),
         message_length <- byte_size(encoded),
         binary_length <- pad_leading(:binary.encode_unsigned(message_length, :big), 4, 0) do
      ElasticAPM.Logger.log(
        :debug,
        "Received message of length #{message_length}"
      )

      state
    end
  end
end
