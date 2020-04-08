defmodule AereplHttpWeb.ReplSessionChannel do
  use AereplHttpWeb, :channel
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]

  defrecord :repl_response, extract(:repl_response, from_lib: "aerepl/src/aere_repl.hrl")
  defrecord :repl_question, extract(:repl_question, from_lib: "aerepl/src/aere_repl.hrl")
  defrecord :repl_state, extract(:repl_state, from_lib: "aerepl/src/aere_repl.hrl")
  defrecord :repl_options, extract(:options, from_lib: "aerepl/src/aere_repl.hrl")


  def join("repl_session:lobby", _payload, socket) do
    send(self(), :init)
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("query", %{"input" => q, "state" => st_ser}, socket) do
    Logger.debug("Size of serialized state: " <> Integer.to_string(String.length(st_ser)))
    {:ok, st_bin} = Base.decode64(st_ser)
    st = :erlang.binary_to_term(st_bin)

    {:repl_response,
     output,
     warnings,
     status
    } = :aere_repl.process_string(st, q)
    msg = List.to_string(:aere_repl.render_msg(st, output))

    push(socket, "response",
      %{"message" => msg,
        "warnings" => warnings,
        "state" => case status do
                     {:success, st1} -> Base.encode64(:erlang.term_to_binary(st1))
                     _ -> Base.encode64(:erlang.term_to_binary(st))
                   end
      })
    {:reply, :ok, socket}
  end

  def handle_info(:init, socket) do
    st0 = :aere_repl.init_state()
    opt0 = repl_state(st0, :options)
    opt1 = repl_options(opt0, colors: :none)
    st = repl_state(st0, options: opt1)

    push(socket, "response", %{"message" => List.to_string(:aere_repl.banner()),
                               "state" => Base.encode64(:erlang.term_to_binary(st))
                              })
    {:noreply, socket}
  end

end
