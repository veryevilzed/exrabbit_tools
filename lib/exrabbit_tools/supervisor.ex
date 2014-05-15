defmodule Exrabbit.Tools.Supervisor do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  defp start_rabbit_handler(opts) do
    name = Dict.get opts, :name, :unnamed
    :pg2.create(name)
    worker(Exrabbit.Tools.Handler, [opts], [id: name]),
  end

  def init([]) do
    children = Keyword.get(Mix.Project.config, :rabbitmq_handlers, []) |> Enum.map start_rabbit_handler
    supervise(children, strategy: :one_for_one)
  end
end
