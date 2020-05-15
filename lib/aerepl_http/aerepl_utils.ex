defmodule ReplUtils do
  require Logger

  def init_state() do
    st = :aere_repl.init_state()
    op = :erlang.element(5, st)

    # NOTE: REMEMBER TO UPDATE THE IDX AFTER REPL UPDATE
    op1 = :erlang.setelement(10, op, true)
    st1 = :erlang.setelement(5, st, op1)

    st1
  end

  def state_from_response(prev_state, resp) do
    case resp do
      {:repl_response, _, _, {:success, st1}} -> {:repl_state, st1}
      {:repl_response, _, _, _} -> {:repl_state, prev_state}
      {:repl_question, _, _, _, _} -> {:repl_question, prev_state, resp}
    end
  end

  def render(state, repl_str), do: state |> :aere_repl.render_msg(repl_str) |> List.to_string()

  def render_response(_, st) when elem(st, 0) == :repl_state,
    do: %{"status" => "success", "output" => "", "warnings" => []}

  def render_response(prev_state, {:repl_response, output, warnings, status}) do
    state =
      case status do
        {:success, new_state} -> new_state
        _ -> prev_state
      end

    case status do
      :internal_error -> Logger.error(render(state, output))
      _ -> :ok
    end

    %{
      "status" =>
        case status do
          {:success, _} -> "success"
          :error -> "error"
          :internal_error -> "internal_error"
          :ask -> "ask"
        end,
      "output" =>
        case status do
          :internal_error -> "internal error"
          _ -> render(state, output)
        end,
      "warnings" => for(w <- warnings, do: render(state, w))
    }
  end

  def render_response(prev_state, resp) when elem(resp, 0) == :repl_question,
    do: render_response(prev_state, :aere_repl.question_to_response(resp))

  def render_response(any), do: render_response(:aere_repl.init_state(), any)
end
