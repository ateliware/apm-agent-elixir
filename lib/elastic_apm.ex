defmodule ElasticAPM do
  @moduledoc """
  This is the Controller Plug module, it's called every time there's a request.
  """
  @doc """
  A module plug implements an init function to initialize the options
  """
  def init(default), do: default

  @doc """
  A module plug implements an call function with receive connection and initialize options.
  """
  def call(conn, _default) do
    before_send(conn)
    conn
  end

  @doc """
  Get transtaction from conn.

  Returns a Map with transaction data.
  ## Examples
      iex> ElasticAPM.before_send(conn)
      {:ok, %Transaction{}}
  """
  def before_send(conn) do
    full_name = action_name(conn)
    uri = "#{conn.request_path}"

    add_ip_context(conn)
    #TODO create a transaction in this function
  end

  @doc """
  Get action name info from conn.

  Returns String with controller and action name.
  
  ## Examples
  
      iex> ElasticAPM.action_name(conn)
      "PageController#index"
  """
  def action_name(conn) do
    controller_name = conn.private[:phoenix_controller]
    action_name = conn.private[:phoenix_action]

    # a string like "Elixir.TestappPhoenix.PageController#index"
    "#{controller_name}##{action_name}"
    # Split into a list
    |> String.split(".")
    # drop "Elixir.TestappPhoenix", leaving just ["PageController#index"]
    |> Enum.drop(2)
    # Probably just "joining" a 1 elem array, but recombine this way anyway in case of periods
    |> Enum.join(".")
  end

  @doc """
  Get IP from user.

  ## Examples

      iex> ElasticAPM.add_ip_context(conn)
      "172.10.0.1"
  """
  def add_ip_context(conn) do
    remote_ip =
      case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
        [forwarded_ip | _] ->
          forwarded_ip

        _ ->
          conn.remote_ip
          |> Tuple.to_list()
          |> Enum.join(".")
      end
  end
end
