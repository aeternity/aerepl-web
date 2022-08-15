defmodule AereplHttpWeb.ReplSessionChannel do
  use AereplHttpWeb, :channel
  require Logger

  def join("repl_session:lobby", _payload, socket) do
    send(self(), :init)
    {:ok, socket}
  end

  def handle_in("query", %{"input" => input, "state" => bin_state}, socket) do
    state0 = decrypt(bin_state)
    me = self()
    spawn(fn -> send(me, :aere_repl.process_input(state0, input)) end)
    receive do
      {:repl_response, msg, _, status} ->
        state1 = case status do
                   {_, s} -> s
                   _ -> state0
                 end
        msg_str = :aere_theme.render(msg)
        resp = %{"msg" => :binary.list_to_bin(msg_str), "state" => encrypt(state1)}
        push(socket, "response", resp)
        {:noreply, socket}
    after
      20000 ->
        resp = %{"msg" => "TIMEOUT", "state" => bin_state}
        push(socket, "response", resp)
        {:noreply, socket}
    end
  end

  def handle_info(:init, socket) do
    state = :aere_repl.init_state(%{:theme => %{}, :call_gas => 10000000, :locked_opts => [:call_gas]})
    msg = :aere_theme.render(:aere_msg.banner())
    resp = %{"msg" => :binary.list_to_bin(msg), "state" => encrypt(state)}
    push(socket, "response", resp)
    {:noreply, socket}
  end

  def encrypt(term) do
    bin = :erlang.term_to_binary(term, [{:compressed, 9}])
    str = :binary.bin_to_list(bin)
    str
  end

  def decrypt(str) do
    bin = :binary.list_to_bin(str)
    term = :erlang.binary_to_term(bin)
    term
  end
end
