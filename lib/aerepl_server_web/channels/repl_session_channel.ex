defmodule AereplServerWeb.ReplSessionChannel do
  use AereplServerWeb, :channel
  require Logger

  alias AereplServer.{
    SessionData,
    SessionService,
  }

  def join("repl_session:lobby", payload, socket) do
    send(self(), {:init, payload})
    {:ok, socket}
  end

  def handle_in("query", %{"input" => input, "user_session" => session_id}, socket) do
    out = GenServer.call(AereplServer.SessionService.via(session_id), {:repl_input_text, input})

    resp = %{"msg" => out}
    push(socket, "response", resp)

    {:noreply, socket}
  end
  def handle_in("load", %{"files" => files, "user_session" => session_id}, socket) do
    filemap = for %{"filename" => filename,
                    "content" => content} <- files,
      do: {String.to_charlist(filename), content}

    out = GenServer.call(
      AereplServer.SessionService.via(session_id),
      {:repl_load_files, filemap}
    )

    resp = %{"msg" => out}
    push(socket, "response", resp)

    {:noreply, socket}
  end

  def handle_info({:init, payload}, socket) do
    session_id =
      case payload do
        %{user_session: token} ->
          token
        _ ->
          session = SessionData.new()
          {:ok, _pid} = SessionService.start(session)
          session.id
      end
    msg = GenServer.call(SessionService.via(session_id), :banner)
    resp = %{"msg" => msg, "user_session" => session_id}
    push(socket, "response", resp)
    {:noreply, socket}
  end
end
