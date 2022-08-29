defmodule AereplHttpWeb.ReplSessionChannel do
  use AereplHttpWeb, :channel
  require Logger

  def join("repl_session:lobby", _payload, socket) do
    send(self(), :init)
    {:ok, socket}
  end

  def handle_in("query", %{"input" => input, "state" => bin_state}, socket) do
    state0 = decrypt(bin_state)
    case ReplUtils.eval_input(input, state0) do
      :timeout ->
        push_response("Timeout.", socket)
      {msg, state1} ->
        push_response(msg, state1, socket)
    end
    {:noreply, socket}
  end
  def handle_in("load", %{"files" => files, "state" => bin_state}, socket) do
    state0 = decrypt(bin_state)
    case check_file_sizes(files) do
      :too_big ->
        push_response("Files too big.", socket)
        {:noreply, socket}
      :ok ->
        state0 = decrypt(bin_state)
        filemap =
          Map.new(files, fn(%{"filename" => filename,
                               "content" => content}) ->
              {:binary.bin_to_list(filename), content}
          end)
        state1 = ReplUtils.load_files(filemap, state0)
        push_response("Loaded #{length(files)} file(s).", state1, socket)
        {:noreply, socket}
    end
  end

  def push_response(msg, socket) do
    resp = %{"msg" => msg}
    push(socket, "response", resp)
  end
  def push_response(msg, state, socket) do
    resp = %{"msg" => msg, "state" => encrypt(state)}
    push(socket, "response", resp)
  end

  def handle_info(:init, socket) do
    {msg, state} = ReplUtils.init_state()
    resp = %{"msg" => msg, "state" => encrypt(state)}
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
