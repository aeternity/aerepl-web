defmodule UserEntry do
  @moduledoc """
  Structure containing the server side information about the client
  """
  defstruct state: {:repl_state, :aere_repl.init_state()}, last_update: DateTime.utc_now()

  def expired(%{last_update: t}) do
    # expire after 4h
    DateTime.diff(DateTime.utc_now(), t) > 60 * 60 * 4
  end

  def poke(entry), do: %{entry | last_update: DateTime.utc_now()}

  def update(%{state: {:repl_state, st0}} = entry, query) do
    resp = :aere_repl.process_string(st0, query)

    new_state =
      case resp do
        {:repl_response, _, _, {:success, st1}} -> {:repl_state, st1}
        {:repl_response, _, _, _} -> {:repl_state, st0}
        {:repl_question, _, _, _, _} -> {:repl_question, st0, resp}
      end

    msg = ReplUtils.render_response(st0, resp)

    {poke(%{entry | state: new_state}), msg}
  end

  def update(%{state: {:repl_question, prev_state, quest}} = entry, query) do
    {answer_status, resp} = :aere_repl.answer(quest, String.to_charlist(String.trim(query)))

    msg = ReplUtils.render_response(prev_state, resp)

    new_state =
      case answer_status do
        :retry ->
          {:repl_question, prev_state, resp}

        :accept ->
          {:repl_state, resp}
      end

    {poke(%{entry | state: new_state}), msg}
  end
end
