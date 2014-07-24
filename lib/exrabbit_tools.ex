defmodule Exrabbit.Tools do
  use Application

  # See http://elixir-lang.org/docs/stable/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    :pg2.start
    Exrabbit.Tools.Supervisor.start_link
  end

  def join(name, pid) do 
    :pg2.join(String.to_atom("#{name}_listeners"), pid)
  end

  def leave(name, pid) do 
    :pg2.leave(String.to_atom("#{name}_listeners"), pid)
  end

end
