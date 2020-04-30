defmodule ReplUtils do
  def render(state, repl_str), do: state |> :aere_repl.render_msg(repl_str) |> List.to_string()

  def render_response(_, st) when elem(st, 0) == :repl_state,
    do: %{"status" => "success", "output" => "", "warnings" => []}

  def render_response(prev_state, {:repl_response, output, warnings, status}) do
    state =
      case status do
        {:success, new_state} -> new_state
        _ -> prev_state
      end

    %{
      "status" =>
        case status do
          {:success, _} -> "success"
          :error -> "error"
          :internal_error -> "internal_error"
          :ask -> "ask"
        end,
      "output" => render(state, output),
      "warnings" => for(w <- warnings, do: render(state, w))
    }
  end

  def render_response(prev_state, resp) when elem(resp, 0) == :repl_question,
    do: render_response(prev_state, :aere_repl.question_to_response(resp))

  def render_response(any), do: render_response(:aere_repl.init_state(), any)
end
