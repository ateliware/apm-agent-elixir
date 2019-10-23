defmodule ElasticAPM do
  @moduledoc """
  Documentation for ElasticApm.
  """
  def init(default), do: default

  def call(conn, _default) do
    require IEx; IEx.pry()
    before_send(conn)
  end

  def before_send(conn) do
    full_name = action_name(conn)
    uri = "#{conn.request_path}"

    add_ip_context(conn)
    IO.inspect(full_name)
  end

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

  defp add_ip_context(conn) do
    remote_ip =
      case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
        [forwarded_ip | _] ->
          forwarded_ip

        _ ->
          conn.remote_ip
          |> Tuple.to_list()
          |> Enum.join(".")
      end
      IO.inspect(remote_ip)
  end
end
