defmodule Exrabbit.Tools.Supervisor do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  defp start_rabbit_handler(opts) do
    name = case Dict.get opts, :name, :unnamed do
      name when is_binary name -> binary_to_atom(name)
      name -> name
    end
    :pg2.create(binary_to_atom "#{name}_listeners" )
    worker(Exrabbit.Tools.Handler, [opts], [id: name])
  end

  def get_listeners(configs), do: Enum.map configs, &( start_rabbit_handler &1 )

  def init([]) do
    #children = Keyword.get(Mix.Project.config, :rabbitmq_handlers, []) |> get_listeners
    supervise([], strategy: :one_for_one)
  end
end
