// NOTE: THIS WAS NOT WRITTEN BY A FRONTEND DEVELOPER
// DON'T JUDGE ME

import {Socket} from "phoenix";
var AU = require('ansi_up');
var ansi = new AU.default;

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

let channel = socket.channel("repl_session:lobby", {});

let currentPrompt       = document.getElementById("prompt");
let queryInput          = document.getElementById("query-input");
let outputContainer     = document.getElementById("outputs");

let newlineButton       = document.getElementById("new-line");
let submitButton        = document.getElementById("submit");

let contractEditor      = document.getElementById("editor");
let loadButton          = document.getElementById("load");

var session = null;

function handle_response(payload) {
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
    let query = queryInput.value.trim();
    let prompt = currentPrompt.innerText + "> ";

    let messageItem = document.createElement("li");
    messageItem.innerText = prompt + query;
    messageItem.classList.add("in");
    outputContainer.appendChild(messageItem);

    channel.push("query", {input: query,
                           user_session: session
                          })
        .receive("ok", handle_response);
    queryInput.value = "";
}

function insertNewLine() {
    let pos = queryInput.selectionStart;
    let input = queryInput.value;
    let left = input.substr(0, pos);
    let right = input.substr(pos, input.length);
    input = left + '\n' + right;
    queryInput.value = input;
    queryInput.focus();
}

function loadFiles() {
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
    let prompt_text = prompt + "> ";
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

channel.on("response", payload => {
    handle_response(payload)
});

channel.onError( () => alert("Channel error.") );
channel.onClose( () => {
    update_prompt("(CLOSED)");
    alert("The channel has been closed. Please refresh to start a new session.");
});


channel.join()
    .receive("ok", resp => { console.log("Joined aerepl lobby."); })
    .receive("error", resp => {
        update_prompt("(CHANNEL ERROR)");
        alert("Could not establish the connection.");
    });

export default socket;
