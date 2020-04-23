# AEREPL HTTP

## Description
**AEREPL HTTP** is a simple web application, which provides an interface to [AEREPL](https://github.com/aeternity/aerepl), which stands for [Read Execute Eval Loop](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop), which allows executing [Æternity Sophia Smart Contract Language](https://github.com/aeternity/aesophia/blob/lima/docs/sophia.md) in an interactive way.

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

## Protocol

To communicate with the server you will need to use channels provided by Phoenix. Example of usage can be seen in the `assets/js/socket.js`.

The server awaits for incoming connections and assigns a session key to each user. Each response from the server is in the JSON format:
```
{
  "key" : string
  "output" : string
  "status" : "success"|"error"|"internal_error"|"ask"
}
```
Where:
 - `key` describes the session key /TODO: should be a cookie actually/
 - `output` is the message to be printed out
 - `status` tells the type of the response:
   - `success` is a regular output with successful outcome
   - `error` means the query wasn't processed at all because of some mistake on the user side. This includes for example type errors, bad syntax, misusing the REPL features etc.
   - `internal error` is the error on the REPL side. The output will probably contain the REPL stacktrace which will be a valuable information if reported to the developers.
   - `ask` indicates that the REPL was asked a question. It should provide the information about valid answers and the default option. If the user replies with empty input the default option will be chosen. If the input won't match with any of the options the question will be re-asked.
   

The query payload is described by the following structure:
```
{
  "key" : string
  "input" : string
}
```
The `key` must match the key of the session provided by server. `input` contains the text of the user query.

**Every session will automatically die if not used for 4 hours.**
