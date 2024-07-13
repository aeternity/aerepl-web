defmodule AereplServerWeb.ReplSessionChannel do
  use AereplServerWeb, :channel
  require Logger

  alias AereplServer.{
    SessionService,
  }


  @doc """
  Initializes a channel. Joins an existing session if `payload.user_session` is provided; otherwise
  creates a new session with fresh REPL state.

  Reply fields:

  - `"user_session"` (`string`): session id of the newly created session
  """
  def join("repl_session:lobby", payload, socket) do
    client_id =
      case payload do
        %{"user_session" => token} ->
          token
        _ ->
          new_client_id()
      end

    config = Map.get(payload, "config", %{})

    SessionService.try_start(client_id, config)

    resp = %{"user_session" => client_id}
    {:ok, resp, socket}
  end


  def repl_call_str(client_id, input, socket) do
    output = SessionService.repl_call_str(client_id, input)
    prompt = SessionService.repl_prompt(client_id)

    case output do
      :finish ->
        {:stop,
         {:shutdown, :closed},
         {:ok, %{"msg" => "bye!", "prompt" => "Bye!"}},
         socket
        }

      {:error, msg} ->
        {:reply,
         {:ok, %{"msg" => msg, "prompt" => prompt}},
         socket
        }

      :ok ->
        {:reply,
         {:ok, %{"prompt" => prompt}},
         socket
        }

      msg ->
        {:reply,
         {:ok, %{"msg" => msg, "prompt" => prompt}},
         socket
        }
    end
  end

  def repl_call(client_id, data, socket) do
    output = SessionService.repl_call(client_id, data)
    prompt = SessionService.repl_prompt(client_id)
    rendered = SessionService.repl_render(client_id, output)

    case JSON.encode(output) do
      {:ok, json} ->
        resp = %{"msg" => rendered,
                 "raw" => json,
                 "prompt" => prompt,
                }
        {:reply, {:ok, resp}, socket}
      _ ->
        {:reply, {:error, %{"msg" => "Object cannot be encoded as JSON", "prompt" => prompt}}, socket}
    end
  end


  def repl_cast(client_id, data, socket) do
    SessionService.repl_cast(client_id, data)
    {:noreply, socket}
  end


  def repl_render(client_id, data, socket) do
    str = SessionService.repl_render(client_id, data)
    {:reply, {:ok, str}, socket}
  end


  def handle_in("call_str", %{"input" => input, "user_session" => client_id}, socket) do
    repl_call_str(client_id, input, socket)
  end

  def handle_in("call", %{"data" => data, "user_session" => client_id}, socket) do
    repl_call(client_id, data, socket)
  end

  def handle_in("cast", %{"data" => data, "user_session" => client_id}, socket) do
    repl_cast(client_id, data, socket)
  end

  def handle_in("app_version", _, socket) do
    vsn = Application.spec(:aerepl_web, :vsn)
    vsn = List.to_string(vsn)
    {:reply, {:ok, vsn}, socket}
  end

  def handle_in("banner",
    %{"user_session" => client_id
    },
    socket
  ) do
    banner = SessionService.repl_banner(client_id)
    {:reply, {:ok, banner}, socket}
  end

  def handle_in("prompt",
    %{"user_session" => client_id
    },
    socket
  ) do
    prompt = SessionService.repl_prompt(client_id)
    {:reply, {:ok, prompt}, socket}
  end

  ### Direct calls as entrypoints

  def handle_in("reset",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :reset, socket)
  end

  def handle_in("type",
    %{"user_session" => client_id,
      "expr" => expr
    },
    socket
  ) do
    expr = String.to_charlist(expr)
    repl_call(client_id, {:type, expr}, socket)
  end

  def handle_in("state",
    %{"user_session" => client_id,
      "expr" => expr
    },
    socket
  ) do
    expr = String.to_charlist(expr)
    repl_call(client_id, {:state, expr}, socket)
  end

  def handle_in("eval",
    %{"user_session" => client_id,
      "expr" => expr
    },
    socket
  ) do
    expr = String.to_charlist(expr)
    repl_call(client_id, {:eval, expr}, socket)
  end

  def handle_in("load",
    %{"user_session" => client_id,
      "files" => files
    }, socket
  ) do
    files = for file <- files, do: String.to_charlist(file)
    repl_call(client_id, {:load, files}, socket)
  end

  def handle_in("reload",
    %{"user_session" => client_id,
      "files" => files
    },
    socket
  ) do
    files = for file <- files, do: String.to_charlist(file)
    repl_call(client_id, {:reload, files}, socket)
  end

  def handle_in("update_filesystem_cache",
    %{"user_session" => client_id,
      "files" => files
    }, socket
  ) do
    files = for %{"filename" => filename, "content" => content} <- files,
      do: {String.to_charlist(filename), content}

    repl_cast(client_id, {:update_filesystem_cache, files}, socket)
    {:reply, :ok, socket}
  end

  def handle_in("set",
    %{"user_session" => client_id,
      "option" => option,
      "value" => value
    }, socket
  ) do
    option = String.to_charlist(option)
    value = String.to_charlist(value)
    repl_call(client_id, {:set, option, value}, socket)
  end

  def handle_in("help",
    %{"user_session" => client_id,
      "command" => command
    },
    socket
  ) do
    command = String.to_charlist(command)
    repl_call(client_id, {:help, command}, socket)
  end

  def handle_in("help",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :help, socket)
  end

  def handle_in("lookup",
    %{"user_session" => client_id,
      "what" => what
    },
    socket
  ) do
    what = String.to_charlist(what)
    repl_call(client_id, {:lookup, what}, socket)
  end

  def handle_in("disas",
    %{"user_session" => client_id,
      "ref" => ref
    },
    socket
  ) do
    ref = String.to_charlist(ref)
    repl_call(client_id, {:disas, ref}, socket)
  end

  def handle_in("break",
    %{"user_session" => client_id,
      "file" => file,
      "line" => line
    },
    socket
  ) do
    file = String.to_charlist(file)
    repl_call(client_id, {:break, file, line}, socket)
  end

  def handle_in("delete_break",
    %{"user_session" => client_id,
      "id" => id
    },
    socket
  ) do
    repl_call(client_id, {:delete_break, id}, socket)
  end

  def handle_in("delete_break_loc",
    %{"user_session" => client_id,
      "file" => file,
      "line" => line
    },
    socket
  ) do
    file = String.to_charlist(file)
    repl_call(client_id, {:delete_break_loc, file, line}, socket)
  end

  def handle_in("continue",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :continue, socket)
  end

  def handle_in("stepover",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :stepover, socket)
  end

  def handle_in("stepin",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :stepin, socket)
  end

  def handle_in("stepout",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :stepout, socket)
  end

  def handle_in("location",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :location, socket)
  end

  def handle_in("print_var",
    %{"user_session" => client_id,
      "name" => name
    },
    socket
  ) do
    name = String.to_charlist(name)
    repl_call(client_id, {:print_var, name}, socket)
  end

  def handle_in("print_vars",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :print_vars, socket)
  end

  def handle_in("stacktrace",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :stacktrace, socket)
  end

  def handle_in("version",
    %{"user_session" => client_id
    },
    socket
  ) do
    repl_call(client_id, :version, socket)
  end

  def handle_in(_t, _p, socket) do
    {:reply, {:error, "Invalid message"}, socket}
  end


  ### Helpers

  def new_client_id() do
    UUID.uuid4()
  end
end
