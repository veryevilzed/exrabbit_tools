defmodule Exrabbit.Tools.Mixfile do
  use Mix.Project

  def project do
    [app: :exrabbit_tools,
     version: "0.0.1",
     deps: deps]
  end

  def application do
    [applications: [],
     mod: {Exrabbit.Tools, []}]
  end

  defp deps do
    [ { :exrabbit, git: "git@git.appforge.ru:elixir/exrabbit.git" } ]
  end
end
