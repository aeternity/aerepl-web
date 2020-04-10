defmodule AereplHttp.StateKeeper do
  use GenServer
  require Logger

  def add_user(user, states) do
    st = :aere_repl.init_state()
    Map.put(states, user, {:state, st})
  end

  # Client

  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default, name: StateKeeper)
  end

  # Callbacks

  @impl true
  def init(states) do
    {:ok, states}
  end

  @impl true
  def handle_call({:join, user}, _from, states) do
    {:reply, %{
        "output" => List.to_string(:aere_repl.banner()),
        "warnings" => "",
        "status" => "success"
     }, add_user(user, states)}
  end

  def handle_call({:query, user, query}, _from, states) do
    states1 = if Map.has_key?(states, user) do states else add_user(user, states) end
    user_state = Map.get(states, user)
    {new_state, msg} =
      case user_state do
        {:state, st0} ->
          resp = :aere_repl.process_string(st0, query)
          new_state = case resp do
                        {:repl_response, _, _, {:success, st1}} -> {:state, st1}
                        {:repl_response, _, _, _}    -> {:state, st0}
                        {:repl_question, _, _, _, _} -> {:question, st0, resp}
                      end
          msg = ReplUtils.render_response(st0, resp)
          {new_state, msg}
        {:question, prev_state, quest} ->
          {answer_status, resp} =
            :aere_repl.answer(quest, String.to_charlist(String.trim(query)))
          msg = ReplUtils.render_response(prev_state, resp)
          case answer_status do
            :retry ->
              Logger.debug("BADDDd")
              {{:question, prev_state, resp}, msg}
            :accept ->
              Logger.debug("GUTT")
              {{:state, resp}, msg}
          end
      end
    {:reply, msg, Map.put(states1, user, new_state)}
  end

  @impl true
  def handle_cast(:gc, state) do
    {:noreply, state}
  end
end
