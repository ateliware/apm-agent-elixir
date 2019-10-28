defmodule ElasticAPM.Config do
  @moduledoc """
  Public interface to configuration settings. Reads from several configuration
  sources, giving each an opportunity to respond with its value before trying
  the next.

  Application.get_env, and Defaults are the the current ones, with
  an always-nil at the end of the chain.
  """

  alias ElasticAPM.Config.Coercions

  @config_modules [
    {ElasticAPM.Config.Env, ElasticAPM.Config.Env.load()},
    {ElasticAPM.Config.Application, ElasticAPM.Config.Application.load()},
    {ElasticAPM.Config.Defaults, ElasticAPM.Config.Defaults.load()},
    {ElasticAPM.Config.Null, ElasticAPM.Config.Null.load()}
  ]

  def find(key) do
    Enum.reduce_while(@config_modules, nil, fn {mod, data}, _acc ->
      if mod.contains?(data, key) do
        raw = mod.lookup(data, key)

        case coercion(key).(raw) do
          {:ok, c} ->
            {:halt, c}

          :error ->
            ElasticAPM.Logger.log(:info, "Coercion of configuration #{key} failed. Ignoring")
            {:cont, nil}
        end
      else
        {:cont, nil}
      end
    end)
  end

  defp coercion(:monitor), do: &Coercions.boolean/1
  defp coercion(:ignore), do: &Coercions.json/1
  defp coercion(_), do: fn x -> {:ok, x} end
end
