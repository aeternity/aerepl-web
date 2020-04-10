defmodule AereplHttpWeb.ReplSessionChannel do
  use AereplHttpWeb, :channel
  require Logger
  require ReplUtils


  def join("repl_session:lobby", _payload, socket) do
    send(self(), :init)
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("query", %{"input" => q, "key" => key}, socket) do
    resp = GenServer.call(StateKeeper, {:query, key, q})
    push(socket, "response",  Map.put(resp, "key", key))
    {:reply, :ok, socket}
  end

  def handle_info(:init, socket) do
    key =
      :crypto.strong_rand_bytes(256)
      |> Base.url_encode64
      |> binary_part(0, 256)
    Logger.debug("Generated key: " <> key)

    resp = GenServer.call(StateKeeper, {:join, key})
    push(socket, "response", Map.put(resp, "key", key))
    {:noreply, socket}
  end

end
