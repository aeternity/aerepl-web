defmodule StateKeeper do
  @moduledoc """
  Server side session manager
  """
  use GenServer

  def start_link(default) when is_map(default),
    do: GenServer.start_link(__MODULE__, default, name: __MODULE__)

  def join(), do: GenServer.call(__MODULE__, :join)

  def query(user, query), do: GenServer.call(__MODULE__, {:query, user, query})

  def autocomplete(user, query), do: GenServer.call(__MODULE__, {:autocomplete, user, query})

  def deploy(user, code, name), do: GenServer.call(__MODULE__, {:deploy, user, code, name})

  def gc(), do: GenServer.cast(__MODULE__, :gc)

  def init(state), do: {:ok, state}

  def handle_call(:join, _from, state) do
    key = gen_session_id()

    {:reply,
     %{
       "output" => List.to_string(:aere_repl.banner()),
       "warnings" => "",
       "status" => "success",
       "key" => key
     }, add_user(state, key)}
  end

  def handle_call({:query, user, query}, _from, state) do
    case Map.get(state, user, :undefined) do
      :undefined ->
        {:reply, {:error, :no_such_user}, state}

      entry ->
        {new_entry, msg} = UserEntry.update(entry, query)
        {:reply, Map.put(msg, "key", user), Map.put(state, user, new_entry)}
    end
  end

  def handle_call({:autocomplete, user, query}, _from, state) do
    case Map.get(state, user, :undefined) do
      :undefined ->
        {:reply, {:error, :no_such_user}, state}

      %{state: entry_state} ->
        user_state =
          case entry_state do
            {:repl_state, st} -> st
            {:repl_question, st, _} -> st
          end

        typed_ids = :aere_repl.list_names(user_state)

        ids = for {_type, id_erlang} <- typed_ids, do: List.to_string(id_erlang)

        {:reply, %{"names" => for(id <- ids, String.starts_with?(id, query), do: id)}, state}
    end
  end

  def handle_call({:deploy, user, code, name}, _from, state) do
    case Map.get(state, user, :undefined) do
      :undefined ->
        {:reply, {:error, :no_such_user}, state}
      entry ->
        {new_entry, msg} = UserEntry.deploy(entry, code, name)
        {:reply, Map.put(msg, "key", user), Map.put(state, user, new_entry)}
    end
  end

  def handle_cast(:gc, state),
    do: {:noreply, :maps.filter(fn _, e -> not UserEntry.expired(e) end, state)}

  defp add_user(state, user), do: Map.put(state, user, %UserEntry{})

  defp gen_session_id(),
    do: 256 |> :crypto.strong_rand_bytes() |> Base.url_encode64() |> binary_part(0, 256)
end
