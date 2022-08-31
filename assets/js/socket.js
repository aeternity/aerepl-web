// NOTE: THIS WAS NOT WRITTEN BY A FRONTEND DEVELOPER
// DON'T JUDGE ME

import {Socket} from "phoenix";
var AU = require('ansi_up');
var ansi = new AU.default;

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

let channel = socket.channel("repl_session:lobby", {});

let queryInput          = document.getElementById("query-input");
let outputContainer     = document.getElementById("outputs");

let newlineButton       = document.getElementById("new-line");
let submitButton        = document.getElementById("submit");

let contractEditor      = document.getElementById("editor");
let loadButton          = document.getElementById("load");

var state = null;


function submitQuery() {
    let query = queryInput.value.trim();
    let messageItem = document.createElement("li");
    messageItem.innerText = query;
    messageItem.classList.add("in");
    outputContainer.appendChild(messageItem);

    channel.push("query", {input: query,
                           state: state
                          });
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
                          state: state
                         });
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
    var msg = payload.msg;
    state = payload.state ? payload.state : state;
    msg = payload.msg.replace(/^\n|\n$/g, '');
    if(msg !== "") {
        console.log(msg)
        let messageItem = document.createElement("li");
        // let content = document.createElement("template");
        let content_str = ansi.ansi_to_html(msg);
        console.log(content_str)
        messageItem.innerHTML = content_str;
        // messageItem.appendChild(content);
        messageItem.classList.add("out");
        outputContainer.appendChild(messageItem);
    }
});

channel.onError( () => alert("Channel error.") );
channel.onClose( () => alert("The channel has been closed. Please refresh to start a new session.") );


channel.join()
    .receive("ok", resp => { console.log("Joined aerepl lobby."); })
    .receive("error", resp => { alert("Could not establish the connection.") });

export default socket;
