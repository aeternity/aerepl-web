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


  def handle_in("query", %{"input" => input, "user_session" => client_id}, socket) do
    out = AereplServer.SessionService.repl_input_text(client_id, input)
    prompt = AereplServer.SessionService.repl_prompt(client_id)

    resp = %{"msg" => out, "prompt" => prompt}
    push(socket, "response", resp)

    {:noreply, socket}
  end

  def handle_in("load", %{"files" => files, "user_session" => client_id}, socket) do
    filemap = for %{"filename" => filename,
                    "content" => content} <- files,
      do: {String.to_charlist(filename), content}

    out = AereplServer.SessionService.repl_load_files(client_id, filemap)
    prompt = AereplServer.SessionService.repl_prompt(client_id)

    resp = %{"msg" => out, "prompt" => prompt}
    push(socket, "response", resp)

    {:noreply, socket}
  end


  def handle_info({:init, payload}, socket) do
    client_id =
      case payload do
        %{"user_session" => token} ->
          token
        _ ->
          new_client_id()
      end

    SessionService.try_start(client_id)

    msg = SessionService.repl_banner(client_id)
    prompt = AereplServer.SessionService.repl_prompt(client_id)
    resp = %{"msg" => msg, "user_session" => client_id, "prompt" => prompt}
    push(socket, "response", resp)
    {:noreply, socket}
end

  def new_client_id() do
    UUID.uuid4()
  end
end
