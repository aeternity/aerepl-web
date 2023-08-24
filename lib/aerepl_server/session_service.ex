defmodule AereplServer.SessionService do
  @moduledoc """
  User session process.
  """
  use GenServer

  alias AereplServer.SessionData

  def via(client_id) when is_binary(client_id) do
    {:via, Registry, {AereplServer.SessionRegistry, {__MODULE__, client_id}}}
  end


  def repl_ref(%SessionData{id: session_id}) do
    repl_ref(session_id)
  end

  def repl_ref(session_id) when is_binary(session_id) do
    {:global, {:aerepl, session_id}}
  end


  def child_spec(client_id) do
    %{
      id: via(client_id),
      start: {__MODULE__, :start_link, [client_id]},
      restart: :transient,
    }
  end


  def start(client_id) do
    DynamicSupervisor.start_child(
      AereplServer.SessionSupervisor,
      child_spec(client_id)
    )
  end

  def start_link(client_id) do
    IO.inspect("******************** START LINK")
    GenServer.start_link(
      __MODULE__,
      client_id,
      name: via(client_id)
    )
    |> IO.inspect
  end


  def try_start(client_id) do
    case Registry.lookup(AereplServer.SessionRegistry, {__MODULE__, client_id}) do
      [] ->
        start(client_id)
      _ ->
        :already_started
    end
  end


  def stop(client_id) do
    DynamicSupervisor.terminate_child(
      AereplServer.SessionSupervisor,
      via(client_id)
    )
  end


  def terminate(reason, session) do
    GenServer.stop(repl_ref(session), reason)
  end


  def init(client_id) do
    session = SessionData.new(client_id)

    {:ok, _repl} = :aere_gen_server.start_link(
      repl_ref(session),
      options: %{
        :filesystem => {:cached, %{}}
      }
    )

    {:ok, session, {:continue, :init}}
  end


  def handle_continue(:init, session) do
    {:noreply, session}
  end


  def handle_call({:repl_input_text, text}, _from, session) do
    repl = repl_ref(session)

    input = String.to_charlist(text)
    output = :aere_gen_server.input(repl, input)

    session = SessionData.touch(session)
    case output do
      :no_output ->
        {:reply, "ok", session}
      {:ok, msg} ->
        {:reply, render(msg), session}
      {:error, e} ->
        throw({:reply, render(e), session})
    end
  end

  def handle_call({:repl_load_files, filemap}, _from, session) do
    repl = repl_ref(session)
    :ok = :aere_gen_server.update_filesystem_cache(repl, filemap)
    {:reply, "Updated file cache", SessionData.touch(session)}
  end

  def handle_call(:repl_banner, _from, session) do
    repl = repl_ref(session)
    banner = :aere_gen_server.banner(repl)
    {:reply, List.to_string(banner), SessionData.touch(session)}
  end

  def handle_call(:repl_prompt, _from, session) do
    repl = repl_ref(session)
    prompt = :aere_gen_server.prompt(repl)
    {:reply, List.to_string(prompt), SessionData.touch(session)}
  end


  def handle_cast(:timeout_check, session) do
    if SessionData.is_timeout(session) do
      {:stop, {:shutdown, :inactivity}, session}
    else
      {:noreply, session}
    end
  end

  def handle_cast({:schedule_timeout_check, client_id}, session) do
    delay = Time.to_seconds_after_midnight(session.timeout) * 1000

    spawn_link(fn() ->
      Process.sleep(delay)
      GenServer.cast(self(), :timeout_check)
    end)
  end


  ### API

  def repl_input_text(client_id, text) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl_input_text, text})
  end


  def repl_load_files(client_id, filemap) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl_load_files, filemap})
  end


  def repl_banner(client_id) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), :repl_banner)
  end


  def repl_prompt(client_id) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), :repl_prompt)
  end

  def schedule_timeout_check(client_id) do
    GenServer.cast(via(client_id), :timeout_check)
  end

  ### Helpers

  def render(resp) do
    theme = :aere_theme.default_theme()

    List.to_string(:aere_theme.render(theme, resp))
  end
end
