// NOTE: THIS WAS NOT WRITTEN BY A FRONTEND DEVELOPER
// DON'T JUDGE ME

import {Socket} from "phoenix";
var AU = require('ansi_up');
var ansi = new AU.default;

var disabled = true;
var session = null;

let currentPrompt       = document.getElementById("prompt");
let queryInput          = document.getElementById("query-input");
let outputContainer     = document.getElementById("outputs");

let newlineButton       = document.getElementById("new-line");
let submitButton        = document.getElementById("submit");

let contractEditor      = document.getElementById("editor");
let loadButton          = document.getElementById("load");

disableInput();

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

let channel = socket.channel("repl_session:lobby", {});

function enableInput() {
    queryInput.disabled = false;
    newlineButton.disabled = false;
    submitButton.disabled = false;
    contractEditor.disabled = false;
    loadButton.disabled = false;
    disabled = false;
}

function disableInput() {
    queryInput.disabled = true;
    newlineButton.disabled = true;
    submitButton.disabled = true;
    contractEditor.disabled = true;
    loadButton.disabled = true;
    disabled = true;
}

function handle_response(payload) {
    console.log("Received response.");
    console.log(payload.msg);
    var msg = payload.msg;
    var last_prompt = currentPrompt.innerText;
    var prompt = payload.prompt ? payload.prompt : last_prompt;
    session = payload.user_session ? payload.user_session : session;
    msg = payload.msg.replace(/^\n|\n$/g, '');
    if(msg) {
        log_response(msg);
    }
    if(prompt) {
        update_prompt(prompt);
    }
}

function submitQuery() {
    if(disabled) return;

    let query = queryInput.value.trim();
    let prompt = currentPrompt.innerText + "> ";

    let messageItem = document.createElement("li");
    messageItem.innerText = prompt + query;
    messageItem.classList.add("in");
    outputContainer.appendChild(messageItem);

    var t =channel.push("query", {input: query,
                           user_session: session
                          })
        .receive("ok", handle_response)
        .receive("error", handle_response); // TODO why isn't this working?
    queryInput.value = "";
}

function insertNewLine() {
    if(disabled) return;

    let pos = queryInput.selectionStart;
    let input = queryInput.value;
    let left = input.substr(0, pos);
    let right = input.substr(pos, input.length);
    input = left + '\n' + right;
    queryInput.value = input;
    queryInput.focus();
}

function loadFiles() {
    if(disabled) return;

    let contract = contractEditor.value;
    channel.push("load", {files: [{filename: "contract.aes",
                                   content: contract
                                  }],
                          user_session: session
                         });
}

function log_response(msg) {
    let messageItem = document.createElement("li");
    let content_str = ansi.ansi_to_html(msg);
    messageItem.innerHTML = content_str;
    messageItem.classList.add("out");
    outputContainer.appendChild(messageItem);
}

function update_prompt(prompt) {
    let prompt_text = prompt;
    currentPrompt.innerText = prompt_text;
    queryInput.placeholder = prompt_text;
}

newlineButton.addEventListener('click', insertNewLine, false);
submitButton.addEventListener('click', submitQuery, false);
loadButton.addEventListener('click', loadFiles, false);

queryInput.addEventListener("keypress", event => {
    if(event.keyCode === 13 && !event.shiftKey) {
        submitQuery();
    }
});

channel.onError( (e) => {
    console.log("Channel error:", e);
    update_prompt("(ERROR)");
    disableInput();
});
channel.onClose( () => {
    console.log("Channel closed");
    update_prompt("END");
    disableInput();
});


channel.join()
    .receive("ok", resp => {
        console.log("Joined aerepl lobby.");
        session = resp.user_session;
        console.log("Session: ", session);
        var t = channel.push("banner", {user_session: session})
            .receive("ok", handle_response);
        console.log("Session established.");
        enableInput();

    })
    .receive("error", resp => {
        update_prompt("(CHANNEL ERROR)");
        alert("Could not establish the connection.");
    });

export default socket;
