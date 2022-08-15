defmodule AereplHttpWeb.ReplSessionChannel do
  use AereplHttpWeb, :channel
  require Logger

  def join("repl_session:lobby", _payload, socket) do
    send(self(), :init)
    {:ok, socket}
  end

  def handle_in("query", %{"input" => input, "state" => bin_state}, socket) do
    state0 = decrypt(bin_state)
    resp = case eval_input(input, state0) do
      :timeout ->
        %{"msg" => "TIMEOUT", "state" => bin_state}
      {msg, state1} ->
        msg_str = :aere_theme.render(msg)
        %{"msg" => :binary.list_to_bin(msg_str), "state" => encrypt(state1)}
    end
    push(socket, "response", resp)
    {:noreply, socket}
  end
  def handle_in("load", %{"files" => files, "state" => bin_state}, socket) do
    case check_file_sizes(files) do
      :too_big ->
        resp = %{"msg" => "Files too big.", "state" => bin_state}
        push(socket, "response", resp)
        {:noreply, socket}
      :ok ->
        state0 = decrypt(bin_state)
        filemap =
          Map.new(files, fn(%{"filename" => filename, "content" => content}) -> {:binary.bin_to_list(filename), content}
          end)
        state1 = :aere_repl_state.loaded_files(filemap, state0)
        state2 = :aere_repl_state.included_files([], state1)
        state3 = :aere_repl_state.included_code([], state2)
        {_, state4} = eval_input("include \"contract.aes\"", state3)
        resp = %{"msg" => "Loaded #{length(files)} file(s).", "state" => encrypt(state4)}
        push(socket, "response", resp)
        {:noreply, socket}
    end
  end

  def handle_info(:init, socket) do
    state = :aere_repl.init_state(%{:theme => %{}, :call_gas => 100000000, :locked_opts => [:call_gas]})
    msg = :aere_theme.render(:aere_msg.banner())
    resp = %{"msg" => :binary.list_to_bin(msg), "state" => encrypt(state)}
    push(socket, "response", resp)
    {:noreply, socket}
  end

  # TODO: Add actual encryption...
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

  def eval_input(input, state0) do
    me = self()
    worker = :erlang.spawn_opt(
      fn -> send(me, {self(), :aere_repl.process_input(state0, input)}) end,
      [{:max_heap_size, %{size: 100000000, kill: :true, error_logger: :false}}]
    )
    receive do
      {worker, {:repl_response, msg, _, {:ok, state1}}} -> {msg, state1}
      {worker, {:repl_response, msg, _, _}} -> {msg, state0}
    after
      20000 ->
        :timeout
    end
  end

  def check_file_sizes(files) do
    case List.foldl(files, 0, fn
          (%{"filename" => filename, "content" => content}, acc) ->
            byte_size(filename) + byte_size(content) + acc
        end) > 300000 do
      :true -> :too_big
      :false -> :ok
    end
  end
end
