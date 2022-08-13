// NOTE: THIS WAS NOT WRITTEN BY A FRONTEND DEVELOPER
// DON'T JUDGE ME

import {Socket} from "phoenix";

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

let channel = socket.channel("repl_session:lobby", {});


let queryInput          = document.getElementById("query-input");
let outputContainer     = document.getElementById("outputs");
let completionContainer = document.getElementById("completion-list");

let autocompleteButton  = document.getElementById("autocomplete");
let newlineButton       = document.getElementById("new-line");
let submitButton        = document.getElementById("submit");

let deployButton        = document.getElementById("deploy");
let contractName        = document.getElementById("contract-name");
let contractCode        = document.getElementById("contract-code");


var inputBufferBackup = null;
var inputBufferNamePointer = null;
var inputBufferNameBackPointer = null;

var state = null;

function submitQuery() {
    let messageItem = document.createElement("li");
    messageItem.innerText = `${queryInput.value}`;
    messageItem.classList.add("in");
    outputContainer.appendChild(messageItem);

    channel.push("query", {input: queryInput.value.trim(),
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


newlineButton.addEventListener('click', insertNewLine, false);
submitButton.addEventListener('click', submitQuery, false);

queryInput.addEventListener("keypress", event => {
    if(event.keyCode === 13 && !event.shiftKey){
        submitQuery();
    }

    if(!event.ctrlKey) {
        inputBufferBackup = null;
        inputBufferNamePointer = null;
        inputBufferNameBackPointer = null;
    }
});

channel.on("response", payload => {
    var msg = payload.msg;
    state = payload.state;
    console.log("MSG: " + msg)
    msg = payload.msg.replace(/^\n|\n$/g, '');
    if(msg !== "") {
        let messageItem = document.createElement("li");
        messageItem.innerText = msg;
        messageItem.classList.add("out");
        outputContainer.appendChild(messageItem);
    }
});

channel.onError( () => console.log("Aaah, crap. Something has gone wrong with the channel.") );
channel.onClose( () => console.log("The channel has gone away gracefully") );


channel.join()
    .receive("ok", resp => { console.log("Okay, joined successfully"); })
    .receive("error", resp => { console.log("Unable to join", resp); });

export default socket;
