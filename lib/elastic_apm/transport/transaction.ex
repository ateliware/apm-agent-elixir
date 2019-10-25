defmodule ElasticAPM.Transport.Transaction do
  defstruct [:name, :type, :ip, :uri]
end