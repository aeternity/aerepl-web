defmodule StateKeeper do
  @moduledoc """
  Server side session manager
  """
  use GenServer
  require Logger

  defmodule UserEntry do
    @moduledoc """
    Structure containing the server side information about the client
    """
    defstruct state: {:repl_state, :aere_repl.init_state}, last_update: DateTime.utc_now

    def expired(%{last_update: t}) do
      DateTime.diff(DateTime.utc_now, t) > 60 * 60 * 4  # expire after 4h
    end

    def poke(entry) do
      %{entry | last_update: DateTime.utc_now}
    end

    def update(entry = %{state: user_state}, query) do
      {new_state, msg} =
        case user_state do
          {:repl_state, st0} ->
            resp = :aere_repl.process_string(st0, query)
            new_state = case resp do
                          {:repl_response, _, _, {:success, st1}} -> {:repl_state, st1}
                          {:repl_response, _, _, _}    -> {:repl_state, st0}
                          {:repl_question, _, _, _, _} -> {:repl_question, st0, resp}
                        end
            msg = ReplUtils.render_response(st0, resp)
            {new_state, msg}
          {:repl_question, prev_state, quest} ->
            {answer_status, resp} =
              :aere_repl.answer(quest, String.to_charlist(String.trim(query)))
            msg = ReplUtils.render_response(prev_state, resp)
            case answer_status do
              :retry ->
                {{:repl_question, prev_state, resp}, msg}
              :accept ->
                {{:repl_state, resp}, msg}
            end
        end
      {poke(%{entry | state: new_state}), msg}
    end
  end


  def add_user(states, user) do
      Map.put(states, user, %UserEntry{})
  end

  def gen_session_id() do
    raw = :crypto.strong_rand_bytes(256)
    raw |> Base.url_encode64 |> binary_part(0, 256)
  end

  # Client

  def start_link(default) when is_map(default) do
    GenServer.start_link(__MODULE__, default, name: StateKeeper)
  end

  def join() do
    GenServer.call(StateKeeper, :join)
  end

  def query(user, query) do
    GenServer.call(StateKeeper, {:query, user, query})
  end

  def gc() do
    GenServer.cast(StateKeeper, :gc)
  end

  # Callbacks
  @impl true
  def init(states) do
    {:ok, states}
  end

  @impl true
  def handle_call(:join, _from, states) do
    key = gen_session_id()
    {:reply,
     %{
        "output" => List.to_string(:aere_repl.banner()),
        "warnings" => "",
        "status" => "success",
        "key" => key
     },
     add_user(states, key)
    }
  end

  @impl true
  def handle_call({:query, user, query}, _from, states) do
    case Map.get(states, user, :undefined) do
      :undefined ->
        {:reply, {:error, :no_such_user}, states}
      entry ->
        {new_entry, msg} = UserEntry.update(entry, query)
        {:reply, msg |> Map.put("key", user), states |> Map.put(user, new_entry)}
    end
  end

  @impl true
  def handle_cast(:gc, states) do
    {:noreply,
     :maps.filter(fn(_, e) -> not(UserEntry.expired(e)) end, states)
    }
  end
end
