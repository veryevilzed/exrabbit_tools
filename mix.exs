defmodule Exrabbit.Tools.Mixfile do
  use Mix.Project

  def project do
    [app: :exrabbit_tools,
     version: "0.0.2",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  def application do
   [applications: [:logger, :rabbit_common, :exrabbit],
     mod: {Exrabbit.Tools, []}
   ]
  end

  defp deps do
    [ 
      { :exrabbit, github: "d0rc/exrabbit" }
    ]
  end
end
