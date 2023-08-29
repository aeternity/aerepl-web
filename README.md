# æREPL-web

## Description
**æREPL-web** is a web interface to [æREPL](https://github.com/aeternity/aerepl)
which allows executing [æternity Sophia Smart Contract
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
Example of usage can be seen in the `assets/js/socket.js`.

### Example setup

Import the necessary dependency:
```
import {Socket} from "phoenix";
```

To open the channel you will need to join the `repl_session` lobby:
```
let channel = socket.channel("repl_session:lobby", {});
```

Then register the callback for incoming messages:
```
channel.on(/*reponse type*/, payload => {
    ...
});
```

It may be good to register several additional handlers:
```
channel.onError( () => console.log("Error") );
channel.onClose( () => console.log("Successful close") );


channel.join()
    .receive("ok", resp => { console.log("Joined successfully"); })
    .receive("error", resp => { console.log("Unable to join", resp); });
```

To push a message to a channel use the `push` method:

```
channel.push(/*message type*/, /*payload*/);
```

## Protocol

The server receives 2 types of messages: `query` and `load`, and
responds with `response`.

### Sent by the client

#### query

Describes a regular REPL query, like `2 + 2` or `:t 24`. The payload consists of:
```
{
  "state" : string
  "input" : string
}
```

- `input` contains the plaintext of the user query.
- `state` describes the state of the REPL. It should not be modified by the client.

#### load

Loads provided files in a REPL-local environment.

```
{
  "state" : string
  "files" : list({"filename": string, "content": string})
}
```

- `files` is a list of objects describing files to be loaded.
- `state` describes the state of the REPL. It should not be modified by the client.

Loaded files may need to be included manually using Sophia's `include` statement.

### Sent by the server

#### reponse

Regular reponse that is supposed to be displayed as the output.
The first (actually, every) response will contain `key` value that will be treated as the
session identifier. The structure of payload goes as follows:
```
{
  "state" : string?
  "msg" : string
}
```
Where:
 - `state` encapsulates REPL's state. If it is not provided, then the state hasn't changed.
 - `msg` contains the result of the last query in a text form. Ready to be printed out.
