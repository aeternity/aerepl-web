defmodule AereplServerWeb.ReplSessionChannel do
  use AereplServerWeb, :channel
  require Logger

  alias AereplServer.{
    SessionService,
  }


  def join("repl_session:lobby", payload, socket) do
    client_id =
      case payload do
        %{"user_session" => token} ->
          token
        _ ->
          new_client_id()
      end

    SessionService.try_start(client_id)

    resp = %{"user_session" => client_id}
    {:ok, resp, socket}
  end

  def repl_call(client_id, _render = :false, data, socket) do
    repl_call(client_id, :false, data, socket, fn x -> x end)
  end

  def repl_call(client_id, _render = :false, data, socket, cont) do
    output = SessionService.repl_call(client_id, data)

    {:ok, prompt} = AereplServer.SessionService.repl_prompt(client_id)
    resp = %{"msg" => cont.(output), "prompt" => prompt}
    {:reply, {:ok, resp}, socket}
  end

  def repl_call(client_id, _render = :true, data, socket) do
    output = SessionService.repl_call_render(client_id, data)
    {:ok, prompt} = AereplServer.SessionService.repl_prompt(client_id)
    resp = %{"msg" => output, "prompt" => prompt}
    {:reply, {:ok, resp}, socket}
  end


  def repl_cast(client_id, data, socket) do
    SessionService.repl_cast(client_id, data)
    {:noreply, socket}
  end


  def handle_in("query", %{"input" => input, "render" => render, "user_session" => client_id}, socket) do

    output = AereplServer.SessionService.repl_input_text(client_id, input, render)

    prompt =
      case output do
        :finish -> "Bye!"
        _ ->
          {:ok, p} = AereplServer.SessionService.repl_prompt(client_id)
          p
      end

    case output do
      {:ok, msg} ->
        {:reply, {:ok, %{"msg" => msg, "prompt" => prompt}}, socket}
      :ok ->
        {:reply, {:ok, %{"msg" => "", "prompt" => prompt}}, socket}
      :finish ->
        {:stop, {:shutdown, :closed},
         {:ok, %{"msg" => "bye!", "prompt" => prompt}}, socket}
      {:error, msg} ->
        # TODO This should not return :ok
        {:reply, {:ok, %{"msg" => msg, "prompt" => prompt}}, socket}
      msg when render ->
        {:reply, {:ok, %{"msg" => msg, "prompt" => prompt}}, socket}
      msg ->
        case JSON.encode(msg) do
          {:ok, json} ->
            {:reply, {:ok, %{"msg" => json, "prompt" => prompt}}, socket}
          _ ->
            {:reply, {:error, %{"msg" => "Object cannot be encoded in JSON", "prompt" => prompt}}, socket}
        end
    end
  end

  def handle_in("update_files", %{"files" => files, "user_session" => client_id}, socket) do
    # TODO: Better validation here

    filemap = for %{"filename" => filename, "content" => content} <- files, do:
      {String.to_charlist(filename), content}

    AereplServer.SessionService.repl_cast(
      client_id,
      {:update_filesystem_cache, filemap})

    {:ok, prompt} = AereplServer.SessionService.repl_prompt(client_id)

    {:reply, {:ok, %{"msg" => "Files updated", "prompt" => prompt}}, socket}
  end

  def handle_in("skip", %{"user_session" => client_id}, socket) do
    repl_cast(client_id, :skip, socket)
  end
  def handle_in("reset", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :reset, socket)
  end

  def handle_in("type", %{"user_session" => client_id, "render" => render, "expr" => expr}, socket) do
    repl_call(client_id, render, {:type, expr}, socket)
  end

  def handle_in("state", %{"user_session" => client_id, "render" => render, "expr" => expr}, socket) do
    repl_call(client_id, render, {:state, expr}, socket)
  end

  def handle_in("eval", %{"user_session" => client_id, "render" => render, "expr" => expr}, socket) do
    repl_call(client_id, render, {:eval, expr}, socket)
  end

  def handle_in("load", %{"user_session" => client_id, "render" => render, "files" => files}, socket) do
    files = for file <- files, do: String.to_charlist(file)
    repl_call(client_id, render, {:load, files}, socket)
  end

  def handle_in("reload", %{"user_session" => client_id, "render" => render, "files" => files}, socket) do
    repl_call(client_id, render, {:reload, files}, socket)
  end

  def handle_in("update_filesystem_cache", %{"user_session" => client_id, "files" => files}, socket) do
    repl_cast(client_id, {:update_filesystem_cache, files}, socket)
  end

  def handle_in("set", %{"user_session" => client_id, "render" => render, "option" => option, "value" => value}, socket) do
    repl_call(client_id, render, {:set, option, value}, socket)
  end

  def handle_in("help", %{"user_session" => client_id, "render" => render, "command" => command}, socket) do
    repl_call(client_id, render, {:help, command}, socket)
  end

  def handle_in("help", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :help, socket)
  end

  def handle_in("lookup", %{"user_session" => client_id, "render" => render, "what" => what}, socket) do
    repl_call(client_id, render, {:lookup, what}, socket)
  end

  def handle_in("disas", %{"user_session" => client_id, "render" => render, "ref" => ref}, socket) do
    repl_call(client_id, render, {:disas, ref}, socket)
  end

  def handle_in("break", %{"user_session" => client_id, "render" => render, "file" => file, "line" => line}, socket) do
    repl_call(client_id, render, {:break, file, line}, socket)
  end

  def handle_in("delete_break", %{"user_session" => client_id, "render" => render, "id" => id}, socket) do
    repl_call(client_id, render, {:delete_break, id}, socket)
  end

  def handle_in("delete_break_loc", %{"user_session" => client_id, "render" => render, "file" => file, "line" => line}, socket) do
    repl_call(client_id, render, {:delete_break_loc, file, line}, socket)
  end

  def handle_in("continue", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :continue, socket)
  end

  def handle_in("stepover", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :stepover, socket)
  end

  def handle_in("stepin", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :stepin, socket)
  end

  def handle_in("stepout", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :stepout, socket)
  end

  def handle_in("location", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :location, socket)
  end

  def handle_in("print_var", %{"user_session" => client_id, "render" => render, "name" => name}, socket) do
    repl_call(client_id, render, {:print_var, name}, socket)
  end

  def handle_in("print_vars", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :print_vars, socket)
  end

  def handle_in("stacktrace", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :stacktrace, socket)
  end

  def handle_in("version", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :version, socket)
  end

  def handle_in("banner", %{"user_session" => client_id, "render" => render}, socket) do
    repl_call(client_id, render, :banner, socket)
  end

  def handle_in(t, p, socket) do
    IO.inspect("Unknown message `" <> t <> "`:")
    IO.inspect(p)
    {:noreply, socket}
  end


  def new_client_id() do
    UUID.uuid4()
  end
end
