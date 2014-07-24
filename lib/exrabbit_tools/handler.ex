defmodule Exrabbit.Tools.Handler do
  use GenServer
  import Exrabbit.Defs
  require Lager

  def state(), do: %{name: __MODULE__, amqp: nil, channel: nil, amqp_monitor: nil, channel_monitor: nil, pg2: nil, opts: [] }

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Lager.info "Start handler #{inspect name} with opts: #{inspect opts}"
    :gen_server.start_link({:local, name}, __MODULE__, opts, [])
  end

  defp q_subscribe(queue, channel) when is_binary(queue) and queue != "", do: Exrabbit.Utils.subscribe(channel, queue)
  defp q_subscribe(queues, channel) when is_list(queues), do: Enum.each fn(queue)-> q_subscribe(channel, queue) end
  defp q_subscribe(_, _), do: :ok

  defp ex_subscribe(exchange, channel, exchange_queue, key) when is_binary(exchange) and exchange != "" do 
    queue = case exchange_queue do
      qname when is_binary(qname) and qname != "" -> Exrabbit.Utils.declare_queue(channel, qname)
      _ -> Exrabbit.Utils.declare_queue(channel) 
    end
    Exrabbit.Utils.bind_queue(channel, queue, exchange, "")
    Exrabbit.Utils.subscribe channel, queue
  end  
  defp ex_subscribe(exchanges, channel, key) when is_list(exchanges), do: Enum.each fn(exchange)-> ex_subscribe(channel, exchange, nil, key) end
  defp ex_subscribe(_, _, _), do: :ok
  defp ex_subscribe(_, _, _, _), do: :ok


  defp rabbit_connect(state=%{opts: opts}) do
    connect = Dict.get opts, :connect, [username: "guest", password: "guest", host: '127.0.0.1', virtual_host: "/", heartbeat: 5]
    amqp = Exrabbit.Utils.connect connect
    channel = Exrabbit.Utils.channel amqp
    Keyword.get(opts, :queue, :nil) |> q_subscribe(channel)
    Keyword.get(opts, :exchange, :nil) |> ex_subscribe(channel, Keyword.get(opts, :exchange_queue, nil), Keyword.get(opts, :exchange_key, ""))
    %{ state | name: Dict.get(opts, :name, __MODULE__),  amqp: amqp, channel: channel, amqp_monitor: :erlang.monitor(:process, amqp), channel_monitor: :erlang.monitor(:process, channel) }
  end

  def init(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    :erlang.send_after 600, self, :init 
    { :ok, %{ state() | opts: opts, pg2: String.to_atom "#{name}_listeners" } }
  end

  def handle_call({:publish, exchange, routing_key, message}, _from, state=%{channel: channel}) do
    Lager.info "Try to Send #{exchange}(#{routing_key}) message #{message} ..."
    {:reply, Exrabbit.Utils.publish(channel, exchange, routing_key, message, :wait_confirmation), state}
  end

  def handle_call(_, _from, state=%{amqp: nil}), do: { :reply, :connection_down, state }

  def handle_call(_, _from, state=%{}), do: { :reply, :error, state }
  
  def handle_info({basic_deliver(delivery_tag: tag), amqp_msg(payload: body)}, state=%{channel: channel, pg2: pg2_name, name: name}) do
    :pg2.get_members(pg2_name) |> Enum.each fn(pid) ->
      case :gen_server.call pid, {:rabbit, {body, name} } do
        :ok -> Exrabbit.Utils.ack channel, tag
        _ -> Exrabbit.Utils.nack channel, tag
      end
    end
    { :noreply, state }
  end

  def handle_info(:init, state=%{}) do
    state = rabbit_connect(state)
    { :noreply, state }
  end

  def handle_info({:'DOWN', monitor_ref, _type, _object, _info}, state=%{name: name, amqp: amqp, amqp_monitor: amqp_monitor, channel_monitor: channel_monitor}) do
    case monitor_ref do
      ^amqp_monitor -> :ok
      ^channel_monitor ->
        Exrabbit.Utils.disconnect amqp
    end
    raise "#{name}: somebody died, we should do it too..."
    { :noreply, state }
  end

  def handle_info(_, state=%{}), do: { :noreply, state }

  def terminate(r, %{amqp: amqp, opts: opts}) do
    name = Keyword.get(opts, :name, __MODULE__)
    Lager.error "Handler #{inspect name} terminate: #{inspect r}"
    Exrabbit.Utils.disconnect(amqp)
  end

end
