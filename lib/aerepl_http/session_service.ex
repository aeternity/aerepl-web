defmodule AereplHttp.SessionService do
  @moduledoc """
  User session process.
  """
  use GenServer

  alias AereplHttp.SessionData

  def via(session_id) when is_binary(session_id) do
    {:via, Registry, {AereplHttp.SessionRegistry, {__MODULE__, session_id}}}
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
      AereplHttp.SessionSupervisor,
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
    {:ok, _repl} = :aere_gen_server.start_link(repl_ref(session), [])
    {:ok, session, {:continue, :init}}
  end

  def handle_continue(:init, session) do
    {:noreply, session}
  end

  def handle_call({:repl_input_text, text}, _from, session) do
    repl = repl_ref(session)

    output = case :aere_parse.parse(text |> to_charlist()) do
               {:error, e} ->
                 throw({:reply, render(e), session})
               command ->
                 GenServer.call(repl, :bump_nonce)
                 GenServer.call(repl, command)
             end

    case output do
      {:ok, msg} ->
        {:reply, render(msg), session}
      {:error, e} ->
        throw({:reply, render(e), session})
    end
  end

  # def handle_call({:repl_load_files, filemap}, _from, session) do
  #   repl = repl_ref(session)

  #   output =  _


  #   case output do
  #     {:ok, msg} ->
  #       {:reply, render(msg), session}
  #     {:error, e} ->
  #       throw({:reply, render(e), session})
  #   end
  # end

  def handle_call(:banner, _from, session) do
    banner = GenServer.call(repl_ref(session), :banner)
    {:reply, List.to_string(banner), session}
  end

  def render(resp) do
    theme = :aere_theme.empty_theme()

    List.to_string(:aere_theme.render(theme, resp))
  end
end
