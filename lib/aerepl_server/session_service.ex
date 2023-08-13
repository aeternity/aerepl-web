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
