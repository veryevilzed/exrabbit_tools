defmodule Exrabbit.Tools.Mixfile do
  use Mix.Project

  def project do
    [app: :exrabbit_tools,
     version: "0.0.1",
     elixir: "~> 0.13.2",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [],
     mod: {Exrabbit.Tools, []}]
  end

  def dev, do: [
    rabbitmq_handlers: [
      name: :rabbit_test_1,
      connect: [
        username: "guest",
        password: "guest",
        host: '127.0.0.1',
        virtual_host: "/",
        heartbeat: 5
        ],
      queue: "test1",
      exchange: nil
    ]
  ]

  defp deps do
    [ { :exrabbit, path: "../exrabbit/" } ]
  end
end
