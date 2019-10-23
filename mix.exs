defmodule ElasticApm.MixProject do
  use Mix.Project

  def project do
    [
      app: :elastic_apm,
      version: "0.0.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElasticAPM.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.18", only: :dev},
      {:telemetry, "~> 0.4.0 or ~> 0.3.0", optional: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description do
  """
  ateliware's Elastic APM agent for Elixir
  """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Leticia Sales", "Samuel Meira"],
      organization: ["ateliware"],
      license: ["MIT"],
      links: %{"GitHub" => "https://github.com/ateliware/apm-agent-elixir"}
    ]
  end
end
