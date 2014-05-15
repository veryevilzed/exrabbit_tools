defmodule Exrabbit.Tools.Handler do
  use GenServer.Behaviour

  defrecord State, [name: __MODULE__, amqp: nil, channel: nil, amqp_monitor: nil, channel_monitor: nil, opts: [] ]

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Lager.info "Start provider server #{name}"
    :gen_server.start_link(__MODULE__, opts, [])
  end

  defp q_subscribe(queue, channel) when is_binary queue and queue != "" do 
    Exrabbit.Utils.subscribe channel, queue
    IO.puts "Subscribe to queue #{queue}"
  end
  defp q_subscribe(queues, channel) when is_list queues, do: Enum.each fn(queue)-> q_subscribe(channel, queue) end
  defp q_subscribe(_, _), do: :ok

  defp ex_subscribe(exchange, channel) when is_binary exchange and exchange != "" do 
    queue = declare_queue(channel) # Анонимная, пока только она
    Exrabbit.Utils.bind_queue(channel, queue, exchange) do
    Exrabbit.Utils.subscribe channel, queue
    IO.puts "Subscribe to exchange #{exchange} with queue #{queue}"
  end  
  defp ex_subscribe(exchanges, channel) when is_list exchanges, do: Enum.each fn(exchange)-> ex_subscribe(channel, exchange) end
  defp ex_subscribe(_, _), do: :ok


  defp rabbit_connect(state=State[opts: opts]) do
    connect = Dict.get opts, :connect, [username: "guest", password: "guest", host: '127.0.0.1', virtual_host: "/", heartbeat: 5]
    amqp = Exrabbit.Utils.connect connect
    channel = Exrabbit.Utils.channel amqp
    Keyword.get(opts, :queue, :nil) |> q_subscribe(channel)
    Keyword.get(opts, :exchange, :nil) |> ex_subscribe(channel)
    state.amqp(amqp).channel(channel).amqp_monitor(:erlang.monitor :process, amqp).channel_monitor(:erlang.monitor :process, channel)
  end

  def init(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    :erlang.send_after 600, self, :init
    { :ok, State.new().opts(opts) }
  end

  def handle_call(_, from, state=State[amqp: nil]) do
    { :reply, :connection_down, state }
  end

  def handle_info({:'basic.deliver'[delivery_tag: tag], :amqp_msg[payload: body]}, state=State[channel: channel, opts: opts]) do
    IO.puts "<-- #{inspect body}"
    Exrabbit.Utils.ack channel, tag
    { :noreply, state }
  end


  def handle_info(:init, state=State[]) do
    state = rabbit_connect(state)
    { :noreply, state }
  end

  def handle_info(message = {:'DOWN', monitor_ref, type, object, info}, state=State[name: name, channel: channel, amqp: amqp, amqp_monitor: amqp_monitor, channel_monitor: channel_monitor]) do
    case monitor_ref do
      ^amqp_monitor -> :ok
      ^channel_monitor ->
        Exrabbit.Utils.disconnect amqp
    end
    raise "#{name}: somebody died, we should do it too..."
  end

  def handle_info(msg, state=State[]) do
    { :noreply, state }
  end

  def terminate(reason, state=State[amqp: amqp, name: name] ) do
    :pg2.leave(name, self)
    Exrabbit.Utils.disconnect(amqp)
  end


end