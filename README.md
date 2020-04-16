# AereplHttp

To start the HTTP server:

  * Install dependencies with `mix deps.get`
  * Update the environment `export ERL_LIBS=$ERL_LIBS:$(pwd)/deps/aerepl/_build/default/lib`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

For the usage of the REPL visit [its documentation](https://github.com/aeternity/aerepl)

**NOTE:** Because of the old rocksdb used by the node, some commands may need to be used with `CXXFLAGS="-Wno-error=shadow -Wno-deprecated-copy -Wno-redundant-move -Wno-pessimizing-move"` flags. See [this issue](https://github.com/aeternity/aeternity/issues/2846) for reference.

## Protocol

To communicate with the server you will need to use channels provided by Phoenix. Example of usage can be seen in the `asstets/js/socket.js`.

The server awaits for incoming connections and assigns a session key to each user. Each response from the server is in the JSON format:
```
{
  "key" : string
  "output" : string
  "status" : "success"|"error"|"internal_error"|"ask"
}
```
Here
 * `key` describes the session key /TODO: should be a cookie actually/
 * `output` is the message to be printed out
 * `status` tells the type of the response:
   * `success` is a regular output with successful outcome
   * `error` means the query wasn't processed at all because of some mistake on the user side. This includes for example type errors, bad syntax, misusing the REPL features etc.
   * `internal error` is the error on the REPL side. The output will probably contain the REPL stacktrace which will be a valuable information if reported to the developers.
   * `ask` indicates that the REPL as asked a question. It should provide the information about valid answers and the default option. If the user replies with empty input the default option will be chosen. If the input won't match with any of the options the question will be re-asked.
   

The query payload is described by the following structure:
```
{
  "key" : string
  "input" : string
}
```
The `key` must match the key of the session provided by server. `input` contains the text of the user query.

Every session will automatically die if not used for 4 hours.
