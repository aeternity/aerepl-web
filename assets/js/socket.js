// NOTE: THIS WAS NOT WRITTEN BY A FRONTEND DEVELOPER
// DON'T JUDGE ME

import {Socket} from "phoenix";

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

let channel         = socket.channel("repl_session:lobby", {});
let queryInput      = document.querySelector("#query-input");
let outputContainer = document.querySelector("#outputs");
let completionContainer = document.querySelector("#completion-list");

var inputBufferBackup = null;
var inputBufferNamePointer = null;
var inputBufferNameBackPointer = null;

var autocompletionId = 0;
var autocompletionList = [];

function isIdChar(c) {
    return c == '.'
        || c == '_'
        || (c >= 'a' && c <= 'z')
        || (c >= 'A' && c <= 'Z');
}

function backupBuffer(trim) {
    inputBufferBackup = queryInput.value;
    inputBufferNamePointer = queryInput.selectionStart;
    inputBufferNameBackPointer = trim.backId;
}

function reloadCompletionList() {
    while (completionContainer.firstChild) {
        completionContainer.removeChild(completionContainer.lastChild);
    }
    if(autocompletionList != null) {
        if(inputBufferBackup === null) {
            let trim = trimForAutocomplete(queryInput.value, queryInput.selectionStart);
            backupBuffer(trim);
        }

        for(var i = 0; i < autocompletionList.length; i+=1) {
            let completionItem = document.createElement("li");
            let i_forever = i;  // yeah, imperative language
            completionItem.innerText = autocompletionList[i];

            completionItem.onclick = function() {
                replaceWithCompletion(i_forever);
            };

            completionContainer.appendChild(completionItem);
        }
    }
}

function replaceWithCompletion(autocompletionId) {
    let before = inputBufferBackup.substring(0, inputBufferNameBackPointer);
    let after = inputBufferBackup.substring(inputBufferNamePointer, inputBufferBackup.length);

    queryInput.value = before + autocompletionList[autocompletionId] + after;
    event.target.selectionStart = (before + autocompletionList[autocompletionId]).length;
    event.target.selectionEnd = event.target.selectionStart;
}


function trimForAutocomplete(input, pos) {
    var backId = pos;
    var whitespaceMode = false;
    while(backId > 0 &&
          ((whitespaceMode &&
            /\s/.test(input[backId - 1])) ||
           isIdChar(input[backId - 1]))) {
        if(input[backId] == '.') {
            // skip whitespaces before dot
            whitespaceMode = true;
        }
        if(! /\s/.test(queryInput.value[backId])) {
            // after skipping all whitespaces go back to normal mode
            whitespaceMode = false;
        }
        backId -= 1;
    }
    return {name: input.substring(backId, pos), backId: backId};
}

queryInput.addEventListener("keypress", event => {
    if(event.keyCode === 13 && !event.shiftKey){
        let messageItem = document.createElement("li");
        messageItem.innerText = `${queryInput.value}`;
        messageItem.classList.add("in");
        outputContainer.appendChild(messageItem);

        channel.push("query", {input: queryInput.value.trim(),
                               key: key
                              });
        queryInput.value = "";
    }

    if(!event.ctrlKey) {
        inputBufferBackup = null;
        inputBufferNamePointer = null;
        inputBufferNameBackPointer = null;
        reloadCompletionList();
    }
});

queryInput.addEventListener("keyup", event => {
    let trim = trimForAutocomplete(queryInput.value, queryInput.selectionStart);

    if(event.keyCode === 32 && event.ctrlKey) {
        if(autocompletionId >= 0 && autocompletionId < autocompletionList.length) {
            if(inputBufferBackup === null) {
                backupBuffer(trim);
            }

            autocompletionId += 1;
            autocompletionId %= autocompletionList.length;

            replaceWithCompletion(autocompletionId);
        }
    } else {
        if(event.keyCode != 17) { // control
            inputBufferBackup = null;
            inputBufferNamePointer = null;
            inputBufferNameBackPointer = null;
            reloadCompletionList();

            channel.push("autocomplete", {input: trim.name, key: key});
        }
    }
});


var key = undefined;  // FIXME: this is a dignity issue that should be fixed

channel.on("response", payload => {
    if((key === payload.key) || !key /* whatever `!key` means */){
        key = payload.key;
        var msg = payload.output.trimEnd().replace(/^\n|\n$/g, '');
        if(msg !== "") {
            let messageItem = document.createElement("li");
            messageItem.innerText = msg;
            messageItem.classList.add("out");
            outputContainer.appendChild(messageItem);
        }
    } else {
        console.log("Invalid key: " + payload.key);
        console.log("Expected: " + key);
    }
});
channel.on("autocomplete", payload => {
    autocompletionId = 0;
    autocompletionList = payload.names;
    reloadCompletionList();
});

channel.onError( () => console.log("Aaah, crap. Something has gone wrong with the channel.") );
channel.onClose( () => console.log("The channel has gone away gracefully") );


channel.join()
    .receive("ok", resp => { console.log("Okay, joined successfully"); })
    .receive("error", resp => { console.log("Unable to join", resp); });

export default socket;
