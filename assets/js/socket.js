// NOTE: THIS WAS NOT WRITTEN BY A FRONTEND DEVELOPER
// DON'T JUDGE ME

import {Socket} from "phoenix";
let AU = require('ansi_up');
let ansi = new AU.default;


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

let channel = socket.channel("repl_session:lobby", {config: {colors: true}});


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
    console.log("Received response:", payload.msg);

    if(payload.raw) {
        console.log("Raw data:", payload.raw);
    }

    var msg = payload.msg || "";

    let last_prompt = currentPrompt.innerText;
    let prompt = payload.prompt || last_prompt;

    session = payload.user_session || session;

    log_response(msg);
    update_prompt(prompt);
}


function submitQuery() {
    if(disabled) return;

    let query = queryInput.value.trim();
    let prompt = currentPrompt.innerText + "> ";

    let messageItem = document.createElement("li");
    messageItem.innerText = prompt + query;
    messageItem.classList.add("in");

    outputContainer.appendChild(messageItem);
    queryInput.value = "";

    channel.push("call_str", {input: query,
                              user_session: session})
        .receive("ok", handle_response);
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

    channel.push("update_filesystem_cache",
                 {files: [{filename: "contract.aes",
                           content: contract
                          }],
                  user_session: session
                 });

    channel.push("load",
                 {files: ["contract.aes"],
                  user_session: session,
                 })
        .receive("ok", handle_response);
}


function log_response(msg) {
    msg = msg.replace(/^\n|\n$/g, '');

    if(!msg) return;

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
    console.log("Channel error:", JSON.stringify(e));
    update_prompt("(ERROR)");
    disableInput();
});

channel.onClose( () => {
    console.log("Channel closed");
    update_prompt("(CLOSED)");
    disableInput();
});


channel.join()
    .receive("ok", resp => {
        console.log("Joined aerepl lobby.");

        session = resp.user_session;
        console.log("Session: ", session);

        channel.push("banner", {user_session: session})
            .receive("ok", log_response);

        channel.push("prompt", {user_session: session})
            .receive("ok", update_prompt);

        channel.push("app_version", {user_session: session})
            .receive("ok", (vsn) => {
                console.log("App version:", vsn);
        });

        console.log("Session established.");
        enableInput();
    })
    .receive("error", resp => {
        update_prompt("(CHANNEL ERROR)");
        alert("Could not establish the connection.");
    });

export default socket;
