if Code.ensure_loaded?(Telemetry) || Code.ensure_loaded?(:telemetry) do
  defmodule ElasticAPM.Instruments.EctoTelemetry do
    @doc """
    Attaches an event handler for Ecto queries.

    Takes a fully namespaced Ecto.Repo module as the only argument. Example:

        ElasticAPM.Instruments.EctoTelemetry.attach(MyApp.Repo)
    """
    def attach(repo_module) do
      query_event =
        repo_module
        |> Module.split()
        |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
        |> Kernel.++([:query])

      :telemetry.attach(
        "ElasticAPM Ecto Instrument Hook for " <> Macro.underscore(repo_module),
        query_event,
        &ElasticAPM.Instruments.EctoTelemetry.handle_event/4,
        nil
      )
    end

    def handle_event(query_event, value, metadata, _config) when is_list(query_event) do
      if :query == List.last(query_event) do
        ElasticAPM.Instruments.EctoLogger.record(value, metadata)
      end
    end
  end
end
