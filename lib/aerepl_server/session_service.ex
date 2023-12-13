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
    GenServer.start_link(
      __MODULE__,
      client_id,
      name: via(client_id)
    )
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
    repl = repl_ref(session)
    options = %{
      :filesystem => {:cached, %{}},
      :return_mode => :render, # TODO this should be not always the case
    }

    {:ok, _repl} = :aere_gen_server.start_link(repl, options: options)
    {:ok, session, {:continue, :init}}
  end


  def handle_continue(:init, session) do
    {:noreply, session}
  end

  def handle_call({:repl, data}, _from, session) do
    IO.inspect "Calling repl"
    session = SessionData.touch(session)

    repl = repl_ref(session)
    output = GenServer.call(repl, data)
    IO.inspect {"Got reply", output}

    case output do
      {:error, e} ->
        throw({:reply, e, session})
      msg ->
        {:reply, msg, session}
    end
  end

  def handle_call({:repl_input_text, text}, _from, session) do
    session = SessionData.touch(session)
    repl = repl_ref(session)

    input = String.to_charlist(text)
    output = :aere_gen_server.input(repl, input)

    resp = case output do
             {:ok, out} -> out
             {:error, err} -> {:error, err}
           end

    {:reply, resp, session}
  end

  def handle_call(:repl_prompt, _from, session) do
    session = SessionData.touch(session)
    repl = repl_ref(session)
    prompt = :aere_gen_server.prompt(repl)
    {:reply, {:ok, prompt}, session}
  end


  def handle_cast({:repl, data}, session) do
    repl = repl_ref(session)
    GenServer.cast(repl, data)
    {:noreply, session}
  end

  def handle_cast(:timeout_check, session) do
    if SessionData.is_timeout(session) do
      {:stop, {:shutdown, :inactivity}, session}
    else
      {:noreply, session}
    end
  end

  def handle_cast(:schedule_timeout_check, session) do
    delay = Time.to_seconds_after_midnight(session.timeout) * 1000

    spawn_link(fn() ->
      Process.sleep(delay)
      GenServer.cast(self(), :timeout_check)
    end)
  end


  ### API

  def repl_call(client_id, data) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl, data})
  end

  def repl_call_render(client_id, data) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl, data})
  end

  def repl_cast(client_id, data) do
    schedule_timeout_check(client_id)
    GenServer.cast(via(client_id), {:repl, data})
  end

  def repl_input_text(client_id, text) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl_input_text, text})
  end

  def repl_prompt(client_id) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), :repl_prompt)
  end

  ### Internal

  def schedule_timeout_check(client_id) do
    GenServer.cast(via(client_id), :timeout_check)
  end

end
