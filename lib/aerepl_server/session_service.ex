defmodule AereplServer.SessionService do
  @moduledoc """
  User session process.
  """
  use GenServer

  alias AereplServer.SessionData

  def via(user_id) when is_binary(user_id) do
    {:via, Registry, {AereplServer.SessionRegistry, {__MODULE__, user_id}}}
  end


  def via_repl(%SessionData{id: session_id}) do
    via_repl(session_id)
  end

  def via_repl(id: session_id) when is_binary(session_id) do
    {:via, Registry, {AereplServer.ReplRegistry, {__MODULE__, session_id}}}
  end


  def child_spec(user_id) do
    %{
      id: via(user_id),
      start: {__MODULE__, :start_link, [user_id]},
      restart: :transient,
    }
  end


  def start(user_id) do
    DynamicSupervisor.start_child(
      AereplServer.SessionSupervisor,
      child_spec(user_id)
    )
  end


  def stop(user_id) do
    DynamicSupervisor.terminate_child(
      AereplServer.SessionSupervisor,
      via(user_id)
    )
  end


  def terminate(reason, session) do
    GenServer.stop(repl_ref(session), reason)
  end


  def init(user_id) do
    session = SessionData.new(user_id)

    {:ok, _repl} = :aere_gen_server.start_link(
      via_repl(user_id),
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

    session = touch(session)
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
    {:reply, "Updated file cache", touch(session)}
  end

  def handle_call(:banner, _from, session) do
    repl = repl_ref(session)
    banner = :aere_gen_server.banner(repl)
    {:reply, List.to_string(banner), touch(session)}
  end


  def handle_cast(:timeout_check, session) do
    if SessionData.is_timeout(session) do
      {:stop, {:shutdown, :inactivity}, session}
    else
      {:noreply, session}
    end
  end


  ### API

  def repl_input_text(client_id, text) do
    GenServer.call(via(client_id), {:repl_input_text, text})
  end


  def repl_load_files(client_id, filemap) do
    GenServer.call(via(client_id), {:repl_load_files, filemap})
  end


  def repl_banner(client_id) do
    GenServer.call(via(client_id), :repl_banner)
  end


  def repl_prompt(client_id) do
    GenServer.call(via(client_id), :repl_prompt)
  end


  def timeout_check(client_id) do
    GenServer.cast(via(client_id), :timeout_check)
  end


  ### Helpers

  def render(resp) do
    theme = :aere_theme.empty_theme()

    List.to_string(:aere_theme.render(theme, resp))
  end


  def touch(session) do
    now = DateTime.utc_now()
    spawn_link(fn() -> GenServer.cast(via(session.client_id)) end)
  end
end
