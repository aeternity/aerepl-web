defmodule AereplServer.SessionService do
  @moduledoc """
  User session process.
  """
  use GenServer

  alias AereplServer.SessionData


  def via(session_id) when is_binary(session_id) do
    {:via, Registry, {AereplServer.SessionRegistry, {__MODULE__, session_id}}}
  end


  def repl_ref(%SessionData{id: session_id}) do
    {:global, {:aerepl, session_id}}
  end


  def child_spec(%SessionData{id: session_id} = session) do
    %{
      id: {__MODULE__, session_id},
      start: {__MODULE__, :start_link, [session]},
      restart: :temporary,
    }
  end


  def start(session) do
    DynamicSupervisor.start_child(
      AereplServer.SessionSupervisor,
      {__MODULE__, session}
    )
  end


  def start_link(%SessionData{id: session_id} = session) do
    GenServer.start_link(
      __MODULE__,
      session,
      name: via(session_id)
    )
  end


  def end_session(session_id) do
    GenServer.stop(via(session_id))
  end


  def init(session) do
    {:ok, _repl} = :aere_gen_server.start_link(repl_ref(session), options: %{:filesystem => {:cached, %{}}})
    {:ok, session, {:continue, :init}}
  end


  def handle_continue(:init, session) do
    {:noreply, session}
  end


  def handle_call({:repl_input_text, text}, _from, session) do
    repl = repl_ref(session)

    input = String.to_charlist(text)
    output = :aere_gen_server.input(repl, input)

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
    {:reply, "Updated file cache", session}
  end


  def handle_call(:banner, _from, session) do
    repl = repl_ref(session)
    banner = :aere_gen_server.banner(repl)
    {:reply, List.to_string(banner), session}
  end


  def render(resp) do
    theme = :aere_theme.empty_theme()

    List.to_string(:aere_theme.render(theme, resp))
  end
end
