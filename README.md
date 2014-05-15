# Exrabbit.Tools

Реактивный хелпер

EXAMPLE USAGE


mix.exs

```

defmodule Demo.Mixfile do
  use Mix.Project

  def project do
    [app: :demo,
     version: "0.0.1",
     deps: deps
     ]
  end

  def application do
    [
     applications: [:exrabbit_tools],
     mod: {Demo, []}
    ]
  end

  def dev, do: [
    rabbit_config: [
      name: :rabbit_demo_1,
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
    [ { :exrabbit_tools, git: "path_to_exrabbit_tools.git" } ]
  end
end


```


supervisor.ex

```

defmodule Demo.Supervisor do
  use Supervisor.Behaviour

  import Exrabbit.Tools.Supervisor, only: [get_listeners: 1]

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = Keyword.get(Mix.Project.config, :rabbit_config, []) |> get_listeners
    supervise(children, strategy: :one_for_one)
  end
end

```

worker.ex

```

defmodule Exrabbit.Tools.Handler do
  use GenServer.Behaviour

  def start_link(_), do: :gen_server.start_link(__MODULE__, [], [])

  def init(_) do
    Exrabbit.Tools.join(:rabbit_demo_1, self)
    { :ok, nil }
  end


  def handle_call({:rabbit, body, :rabbit_demo_1}, _from, _state) do
    # Do here
  end

  def terminate(_, _) do, Exrabbit.Tools.leave(:rabbit_demo_1, self)
end

```