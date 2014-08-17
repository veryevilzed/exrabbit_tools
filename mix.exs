defmodule Exrabbit.Tools.Mixfile do
  use Mix.Project

  def project do
    [app: :exrabbit_tools,
     version: "0.0.1",
     elixir: "~> 0.15.0",
     deps: deps]
  end

  def application do
   [applications: [:logger, :exrabbit, :rabbit_common],
     mod: {Exrabbit.Tools, []}
   ]
  end

  defp deps do
    [ 
      { :exrabbit, github: "d0rc/exrabbit" }
    ]
  end
end
