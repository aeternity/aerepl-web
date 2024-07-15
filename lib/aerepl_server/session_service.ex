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


  def child_spec(client_id, config) do
    %{
      id: via(client_id),
      start: {__MODULE__, :start_link, [client_id, config]},
      restart: :transient,
    }
  end


  def start(client_id, config) do
    DynamicSupervisor.start_child(
      AereplServer.SessionSupervisor,
      child_spec(client_id, config)
    )
  end


  def start_link(client_id, config) do
    GenServer.start_link(
      __MODULE__,
      {client_id, config},
      name: via(client_id)
    )
  end


  def try_start(client_id, config) do
    case Registry.lookup(AereplServer.SessionRegistry, {__MODULE__, client_id}) do
      [] ->
        start(client_id, config)
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


  def init({client_id, config}) do
    session = SessionData.new(client_id)
    repl = repl_ref(session)
    options = %{
      :filesystem => {:cached, %{}},
      :theme => case Map.get(config, "colors", :false) do
                  :true -> :aere_theme.default_theme()
                  :false -> :aere_theme.empty_theme()
                end
    }

    {:ok, _repl} = :aere_gen_server.start_link(repl, options: options)
    {:ok, session, {:continue, :init}}
  end


  def handle_continue(:init, session) do
    {:noreply, session}
  end


  ### Textual user input is parsed to a command and its output is rendered.
  def handle_call({:repl_str, text}, _from, session) do
    session = SessionData.touch(session)
    repl = repl_ref(session)

    input = String.to_charlist(text)
    output = :aere_gen_server.input(repl, input)

    fmt = :aere_gen_server.format(repl, output)
    resp = :aere_gen_server.render(repl, fmt)

    {:reply, resp, session}
  end

  def handle_call({:repl, call}, _from, session) do
    session = SessionData.touch(session)

    repl = repl_ref(session)
    output = GenServer.call(repl, call)

    case output do
      {:error, err} ->
        throw({:reply, {:error, err}, session})
      msg ->
        {:reply, msg, session}
    end
  end

  def handle_call(:repl_prompt, _from, session) do
    session = SessionData.touch(session)
    repl = repl_ref(session)
    prompt = :aere_gen_server.prompt(repl)
    {:reply, prompt, session}
  end

  def handle_call({:repl_render, data}, _from, session) do
    session = SessionData.touch(session)
    repl = repl_ref(session)

    fmt = :aere_gen_server.format(repl, data)
    str = :aere_gen_server.render(repl, fmt)
    {:reply, str, session}
  end

  def handle_call(:repl_banner, _from, session) do
    session = SessionData.touch(session)
    repl = repl_ref(session)
    banner = :aere_gen_server.render(repl, :aere_gen_server.banner())
    {:reply, banner, session}
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

  @doc """
  Textual query as in CLI mode. Input is a string which is parsed to a command, which is then
  executed and finally the output is rendered. Call with `text` equal to `":help"` for more details
  on possible values of that field.
  """
  def repl_call_str(client_id, text) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl_str, text})
  end


  @doc """
  Direct REPL call. Input is exactly as in the `:aere_gen_server` module, and output is not
  rendered.
  """
  def repl_call(client_id, data) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl, data})
  end


  @doc """
  Direct REPL cast. Input is exactly as in the `:aere_gen_server` module, does not return
  anything.
  """
  def repl_cast(client_id, data) do
    schedule_timeout_check(client_id)
    GenServer.cast(via(client_id), {:repl, data})
  end


  @doc """
  Get a hint about the REPL's state (eg. whether it is at a breakpoint). Possible values:

  - `AESO` - when ready
  - `AESO(DBG)` - when at a breakpoint
  - `AESO(ABORT)` - when at an aborted call (eg. due to explicit `abort` call or pattern matching fail)
  """
  def repl_prompt(client_id) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), :repl_prompt)
  end


  @doc """
  Render a value or error returned by a REPL call as a human-readable string. Uses the REPL's
  configuration for coloring and formatting.
  """
  def repl_render(client_id, data) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), {:repl_render, data})
  end


  @doc """
  Get a nice ASCII banner with some version information.
  """
  def repl_banner(client_id) do
    schedule_timeout_check(client_id)
    GenServer.call(via(client_id), :repl_banner)
  end


  ### Internal

  @doc """
  Auxilary check whether the session should be closed due to inactivity.
  """
  def schedule_timeout_check(client_id) do
    GenServer.cast(via(client_id), :timeout_check)
  end

end
