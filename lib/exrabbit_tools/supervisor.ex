defmodule Exrabbit.Tools.Supervisor do
  use Supervisor
  require Logger
  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  
  def get_listeners(configs) do
    configs |> Enum.map fn({name, opts}) -> 
      Logger.debug "Create worker #{name}"
      name = case name do
        name when is_binary name -> String.to_atom(name)
        name -> name
      end
      :pg2.create(String.to_atom "#{name}_listeners")
      worker(Exrabbit.Tools.Handler, [Dict.put(opts, :name, name)], [id: name])
    end
  end

  def init([]) do
    #children = Keyword.get(Mix.Project.config, :rabbitmq_handlers, []) |> get_listeners
    supervise([], strategy: :one_for_one)
  end
end
