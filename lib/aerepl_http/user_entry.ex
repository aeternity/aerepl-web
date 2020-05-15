defmodule UserEntry do
  @moduledoc """
  Structure containing the server side information about the client
  """
  defstruct state: {:repl_state, ReplUtils.init_state()}, last_update: DateTime.utc_now()

  def expired(%{last_update: t}) do
    # expire after 4h
    DateTime.diff(DateTime.utc_now(), t) > 60 * 60 * 4
  end

  def poke(entry), do: %{entry | last_update: DateTime.utc_now()}

  def update(%{state: {:repl_state, st0}} = entry, query) do
    resp = :aere_repl.process_string(st0, query)

    new_state = ReplUtils.state_from_response(st0, resp)

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


  def deploy(%{state: {:repl_question, _, _}} = entry, _, _) do
    {poke(entry), %{
        "status" => :error,
        "output" => "Cannot deploy a contract while answering the question",
        "warnings" => []
     }
    }
  end

  def deploy(%{state: {:repl_state, st0}} = entry, code, name) do
    case String.trim(code) do
      "" -> {poke(entry), %{
                "status" => :error,
                "output" => "Contract is empty",
                "warnings" => []
             }
            }
      _ ->
        name1 = case name do
                  :none -> :none
                  :nil -> :none
                  _ when is_binary(name) -> String.to_charlist(name)
                end

        resp = :aere_repl.to_response(st0, fn () -> :aere_repl.register_tracked_contract(st0, name1, code) end)
        new_state = ReplUtils.state_from_response(st0, resp)

        msg = ReplUtils.render_response(st0, resp)

        {poke(%{entry | state: new_state}), msg}
    end
  end
end
