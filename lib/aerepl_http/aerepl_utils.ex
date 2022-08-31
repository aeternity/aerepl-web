defmodule ReplUtils do
  require Logger

  def init_state() do
    state = :aere_repl.init_state(
      %{theme:       :aere_theme.default_theme(),
        call_gas:    100000000,
        locked_opts: [:call_gas]
      })
    banner = render_msg(:aere_msg.banner())
    {banner, state}
  end

  def eval_input(input, state0) do
    me = self()
    worker = :erlang.spawn_opt(
      fn -> send(me, {self(), :aere_repl.process_input(state0, input)}) end,
      [{:max_heap_size, %{size: 100000000, kill: :true, error_logger: :false}}]
    )
    receive do
      {worker, {:repl_response, msg, _, {:ok, state1}}} ->
        {render_msg(msg), state1}
      {worker, {:repl_response, msg, _, :internal_error}} ->
        Logger.error(msg)
        {"Internal REPL error. Type :reset if the problem persists.", state0}
      {worker, {:repl_response, msg, _, _}} ->
        {render_msg(msg), state0}
    after
      20000 ->
        :timeout
    end
  end

  def load_files(filemap, state0) do
    state1 = :aere_repl_state.loaded_files(filemap, state0)
    state2 = :aere_repl_state.included_files([], state1)
    state3 = :aere_repl_state.included_code([], state2)
    {_, state4} = eval_input("include \"contract.aes\"", state3)
    state4
  end

  def render_msg(msg) do
    :binary.list_to_bin(:aere_theme.render(:aere_theme.default_theme(), msg))
  end
end
