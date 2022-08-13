defmodule AereplHttpWeb.ReplSessionChannel do
  use AereplHttpWeb, :channel
  require Logger

  def join("repl_session:lobby", _payload, socket) do
    send(self(), :init)
    {:ok, socket}
  end

  def handle_in("query", %{"input" => input, "state" => bin_state}, socket) do
    state0 = decrypt(bin_state)
    {msg, state1} = :aere_gen_server.input(input, state0)
    resp = %{"msg" => msg, "state" => encrypt(state1)}
    push(socket, "response", resp)
    {:noreply, socket}
  end

  def handle_info(:init, socket) do
    state = :aere_repl.init_state(%{:theme => :none})
    msg = :aere_gen_server.banner()
    resp = %{"msg" => msg, "state" => encrypt(state)}
    push(socket, "response", resp)
    {:noreply, socket}
  end

  def encrypt(term) do
    bin = Erlang.term_to_binary(term)
    bin
  end

  def decrypt(bin) do
    term = Erlang.binary_to_term(bin)
    term
  end
end
