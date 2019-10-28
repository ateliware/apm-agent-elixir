defmodule ElasticAPM.Utils do
  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  def agent_version do
    Application.spec(:elastic_apm, :vsn) |> to_string
  end
end
