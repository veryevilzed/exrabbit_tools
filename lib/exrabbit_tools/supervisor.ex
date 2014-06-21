defmodule Exrabbit.Tools.Supervisor do
  use Supervisor

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  
  def get_listeners(configs) do
    configs |> Enum.map fn({name, opts}) -> 
      IO.puts "Create worker #{name}"
      name = case name do
        name when is_binary name -> binary_to_atom(name)
        name -> name
      end
      :pg2.create(binary_to_atom "#{name}_listeners")
      worker(Exrabbit.Tools.Handler, [Dict.put(opts, :name, name)], [id: name])
    end
  end

  def init([]) do
    #children = Keyword.get(Mix.Project.config, :rabbitmq_handlers, []) |> get_listeners
    supervise([], strategy: :one_for_one)
  end
end
