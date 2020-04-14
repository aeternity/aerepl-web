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
    resp = StateKeeper.query(key, q)
    StateKeeper.gc()
    case resp do
      {:error, e} -> handle_error(e, key, socket)
      _ ->
        push(socket, "response",  resp)
        {:reply, :ok, socket}
    end
  end

  def handle_info(:init, socket) do
    resp = StateKeeper.join()
    push(socket, "response", resp)
    {:noreply, socket}
  end

  def handle_error(:no_such_user, key, socket) do
    Logger.log("Request from invalid user: " <> inspect key)
    {:noreply, socket}
  end

end
