use Mix.Config

config :logger, backends: []

config :elastic_apm,
  collector_module: ElasticAPM.TestCollector
