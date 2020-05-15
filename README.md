# AEREPL HTTP

## Description
**AEREPL HTTP** is a simple web application, which provides an interface to [AEREPL](https://github.com/aeternity/aerepl), which stands for [Read Eval Print Loop](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), which allows executing [Æternity Sophia Smart Contract Language](https://github.com/aeternity/aesophia/blob/lima/docs/sophia.md) in an interactive way.

## Setup

- Clone the project and get the dependencies:
```
git clone https://github.com/aeternity/aerepl_http
cd aerepl_http && mix deps.get
```
- Update the environment:
```
export ERL_LIBS=$ERL_LIBS:$(pwd)/deps/aerepl/_build/default/lib
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

**Every session will automatically die if not used for 4 hours.**


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

The server receives three types of messages: `query`, `autocomplete` and `deploy`,
and responds with either `response` or `autocomplete`.
To ensure the integrity it will provide the key of the session. The client will need to attach
it to every message to make the server recogize them.

### Sent by the client

#### query

Describes a regular REPL query, like `2 + 2` or `:t 24`. The payload consists of:
```
{
  "key" : string
  "input" : string
}
```
`input` contains the plaintext of the user query.

The `key` must match the key of the session provided by server.

#### autocomplete

Asks the REPL for possible completions of the word. The REPL will reply with `autocomplete` response 
containing list of matching identifiers. The structure is the same as in `query`:
```
{
  "key" : string
  "input" : string
}
```
`input` contains the prefix of some identifier candidate.

The `key` must match the key of the session provided by server.

#### deploy

Deploys the contract in a REPL-local environment. It will be accessible under the variable
provided in the `name` value. If it is not specified, the REPL will generate some reasonable 
name basing on the contract typename avoiding name conflicts.
```
{
  "key" : string
  "code" : string
  "name" : string | null | no value
}
```
`code` contains plaintext source code of the contract. It may contain namespaces, 
import standard libraries and use stateful functions. Currently there is no support
for deploy arguments.

Note that this message will be rejected if the REPL is in the "question mode".

The `key` must match the key of the session provided by server.


### Sent by the server

#### reponse

Regular reponse that is supposed to be displayed as the output.
The first (actually, every) response will contain `key` value that will be treated as the
session identifier. The structure of payload goes as follows:
```
{
  "key" : string
  "output" : string
  "status" : "success"|"error"|"internal_error"|"ask"
  "warnings" : [string]
}
```
Where:
 - `key` describes the session key
 - `output` contains the result of the last query in a text form. Intended to be printed out. 
 - `status` tells the type of the response:
   - `success` is a regular output with successful outcome
   - `error` means the query wasn't processed at all because of some mistake on the user side. This includes for example type errors, bad syntax, misusing the REPL features etc.
   - `internal error` is the error on the REPL side.
   - `ask` indicates that the REPL has asked a question and awaits an answer from the client in the next `query` message.
 - `warnings` is a list of warnings that appeared during query evaluation
 
The `ask` response will appear in cases where the user needs to make some particular decision, eg. their action would
remove something from the context and the REPL want's to ensure that they know what are they doing. In such a case,
in the `output` field there should be message like `do you really want to proceed? [y]n`. To answer this question the client
will need to make a regular `query` call with either `"y"` or `"n"` in the `input` field. If the `input` is empty, the 
option in the brackets will be chosen as the default.

#### autocomplete

Provides the list of identifiers that matched the input of the last `autocomplete` client message.
The payload will contain only a single field `names` with a list of strings describing possible
alternatives.
