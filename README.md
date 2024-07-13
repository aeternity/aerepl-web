# æREPL-web

## Description
**æREPL-web** is a websocket interface to
[æREPL](https://github.com/aeternity/aerepl) which allows executing [æternity
Sophia Smart Contract
Language](https://github.com/aeternity/aesophia/blob/lima/docs/sophia.md)
interactively through Elixir channels.

## Setup

- Clone the project and get the dependencies:
```
git clone https://github.com/aeternity/aerepl-web
cd aerepl-web && mix deps.get
```
- Update the environment:
```
export ERL_LIBS=$ERL_LIBS:$(pwd)/deps/aerepl/_build/prod/lib
```
- Install Node.js dependencies:
```
cd assets && npm install && cd ..
```
- Start Phoenix endpoint:
```
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Connection

To communicate with the server you will need to use channels provided by Phoenix Framework.
The connection is bound to a session on the server side where the REPL's state is kept.
See the example in `assets/js/socket.js`.

### Example setup

Import the necessary dependency:
```js
import {Socket} from "phoenix";
```

To open the channel you will need to join the `repl_session` lobby:
```js
let channel = socket.channel("repl_session:lobby", {});
```

Then register the callback for incoming messages:
```js
channel.on(/*reponse type*/, payload => {
    ...
});
```

It may be good to register several additional handlers:
```js
channel.onError( () => console.log("Error") );
channel.onClose( () => console.log("Successful close") );


channel.join()
    .receive("ok", resp => { console.log("Joined successfully"); })
    .receive("error", resp => { console.log("Unable to join", resp); });
```

To push a message to a channel use the `push` method:

```js
channel.push(/*message type*/, /*payload*/);
```

## Protocol

### Opening a channel

```js
socket.channel("repl_session:lobby", DATA);
```

Fields in `DATA`:

- `user_session` (string, optional) — to rejoin an existing session, specify this
  field. If unspecified, or the session does not exist, a fresh session will be
  created.
- `config` (object, optional) — initial configuration, defaults to `{}`. Fields:
  - `colors` (bool, optional) — if `true`, colors output using ANSI terminal
    coloring. Defaults to `false`.

Response fields:

- `user_session` (string) — identifier of the session. If `user_session` has
  been specified when the channel was opened, this should be the same value.

### Standard responses

Most calls have the same response format. The fields are as follows:

- `user_session` (string, optional)
- `prompt` (string, optional) — the prompt to be displayed to the
  user. Indicates REPL state (eg. whether at breakpoint). If not specified, it
  hasn't changed since the previous call.
- `msg` (string, optional) — human-readable result of the call. If not
  specified, then a success without a comment.
- `raw` (any, optional) — some calls include a JSON of the Erlang value returned
  by the REPL. May be useful if the reply has to be parsed.

### `"call_str"`

CLI-style interface to the REPL.

Input fields:

- `user_session` (string)
- `input` (string) — evaluates textual input query. For more details, type `":help"` here.

Response fields standard.

### `"call"` (unstable)

Raw interface to the underlying Erlang `gen_server`. Don't use unless you really
want to hack.

Input fields:

- `user_session` (string)
- `data` (any) — See
  (aerepl)[https://github.com/aeternity/aerepl?tab=readme-ov-file#generic-server-interface]
  for more details.

### `"cast"` (unstable)

Same as in `call`, but does not return anything.

### `"app_version"`

Input fields: (none)

Response: application version as string.

### `"banner"`

Returns a nice show-offy banner wit the REPL logo and version information.

Input fields:

- `user_session` (string)

Response: banner as string.

### `"prompt"`

Returns a suggestion for the user prompt, which indicates the REPL state.

Input fields:

- `user_session` (string)

Response fields standard. Possible values of `msg`:

- `AESO` — REPL ready state
- `AESO(DBG)` — at breakpoint
- `AESO(ABORT)` — after a reverted execution (eg. due to explicit call to
  `abort` or failed pattern matching)

### `"reset"`

Reset the REPL state.

Input fields:

- `user_session` (string)

Response fields standard.

### `"type"`

Typechecks a Sophia expression

Input fields:

- `user_session` (string)
- `expr` (string) — Sophia expression to typecheck

Response fields standard.

### `"state"`

Sets the in-REPL contract store (the value of `state` in Sophia)

Input fields:

- `user_session` (string)
- `expr` (string) — Sophia expression to provide the new value

Response fields standard.

### `"eval"`

Evaluates a Sophia expression.

Input fields:

- `user_session` (string)
- `expr` (string) — Sophia expression to evaluate.

Response fields standard.

### `"load"`

Loads files into the REPL context. Only the first one will be explicitly
included. Note that the files have to be first uploaded using
`update_filesystem_cache`. It also does not deploy contracts, but only makes
them visible in the REPL context.

Input fields:

- `user_session` (string)
- `files` (list of string) — file names

Response fields standard.

### `"reload"`

Reloads already files that have been loaded. Note that the files have to be
first uploaded using `update_filesystem_cache`.

Input fields:

- `user_session` (string)
- `files` (list of string) — file names to reload. If empty, all will be reloaded.

Response fields standard.

### `"update_filesystem_cache"`

Uploads files to the REPL filesystem cache to make them accessible by the `load`
and `reload` commands. Note that this does not deploy any contracts, but only
makes them visible in the REPL context.

Input fields:

- `user_session` (string)
- `files` (list of objects) — list of file descriptions:
  - `filename` (string) — name of the file
  - `content` (string) — contents of the file

Response is empty.

### `"set"`

Adjusts REPL's behavior. See `:help set` or `aerepl` documentation for more details.

Input fields:

- `user_session` (string)
- `option` (string) — name of the config entry
- `value` (any) — new value

Response fields standard.

### `"help"`

Returns information about commands. Note that it's mostly relevant for CLI-style users.

Input fields:

- `user_session` (string)
- `command` (string, optional) — if specified, returns information about the
  command. Otherwise lists all available commands in CLI style.

Response fields standard.

### `"disas"`

Presents FATE assembly of a thing.

Input fields:

- `user_session` (string)
- `ref` (string) — the thing (eg. contract function) to be disassembled

Response fields standard.

### `"break"`

Sets a breakpoint.

Input fields:

- `user_session` (string)
- `file` (string) — file name
- `line` (integer) — line number

Response fields standard.

### `"delete_break"`

Removes breakpoint by id.

Input fields:

- `user_session` (string)
- `id` (integer) — id of the breakpoint to be removed

Response fields standard.

### `"delete_break_loc"`

Removes breakpoint by location.

Input fields:

- `user_session` (string)
- `file` (string) — file name
- `line` (integer) — line number

Response fields standard.

### `"continue"`

Resumes paused execution.

Input fields:

- `user_session` (string)

Response fields standard.

### `"stepover"`

Moves paused execution by one line in the source code, skipping function calls.

Input fields:

- `user_session` (string)

Response fields standard.

### `"stepin"`

Moves paused execution by one line in the source code, entering function calls.

Input fields:

- `user_session` (string)

Response fields standard.

### `"stepout"`

Moves paused execution until return of the currently visited function.

Input fields:

- `user_session` (string)

Response fields standard.

### `"location"`

Shows location in code of currently paused execution.

Input fields:

- `user_session` (string)

Response fields standard.

### `"print_var"`

Prints value of a local variable in the currently paused execution.

Input fields:

- `user_session` (string)
- `name` — variable name

Response fields standard.

### `"print_vars"`

Prints values of all local variables in the currently paused execution.

Input fields:

- `user_session` (string)

Response fields standard.

### `"stacktrace"`

Prints the stacktrace.

Input fields:

- `user_session` (string)

Response fields standard.

### `"version"`

Returns version information about the REPL itself, FATE, Sophia and aeternity node.

Input fields:

- `user_session` (string)

Response fields standard.


## Examples

### What's the type of `Oracle.query`?

Two ways to do it:

- CLI style: `let r = channel.push("call_str", {input: ":t Oracle.query", user_session: ...})`
- Direct call: `let r = channel.push("type", {expr: "Oracle.query", user_session: ...})`

Then the result can be accessed like `r.receive("ok", resp => console.log(resp.msg))`.

### Deploy a contract

First, obtain the contract source

```js
let src = "contract MyContract = entrypoint f() = 123\n";
```

Upload the source to the REPL file cache. The contract is not deployed, nor even
typechecked yet. If you are working with multiple files, include them all in the
`files` field.

```js
let name = "MyContract.aes";
let fs = [{filename: name, content: src}];

channel.push("update_filesystem_cache", {files: fs, user_session: session});
```

Load the contract in the REPL context. This step is necessary for REPL to know
which files to consider included directly while performing calls.

```js
let result = channel.push("load", {files: [name], user_session: session});
```

Now, the `result` variable contains information about whether the contract was
successfully loaded. This may not be the case for example when there are type errors.

```js
result.receive("ok", (resp) => console.log(resp.msg));
```

There is no direct way to deploy contracts in the REPL, because Sophia/FATE can do it
perfectly fine. To create an instance of the contract, run:

```js
let deploy_cmd = "let my_contract = Chain.create() : MyContract";
channel.push("eval", {expr: cmd, user_session: session});
```

Finally, call the contract using the remote call notation from Sophia:

```js
let call_cmd = "my_contract.f()";
channel.push("eval", {expr: cmd, user_session: session})
    .receive("ok", (resp) => console.log(resp.msg));
```
