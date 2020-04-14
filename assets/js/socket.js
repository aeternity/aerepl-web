import {Socket} from "phoenix";

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

let channel         = socket.channel("repl_session:lobby", {});
let queryInput      = document.querySelector("#query-input");
let outputContainer = document.querySelector("#outputs");

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
});

var key = undefined;  // FIXME: this is a dignity issue that should be fixed

channel.on("response", payload => {
    if((key === payload.key) || !key /* whatever !key means */){
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

channel.onError( () => console.log("Aaah, crap. Something has gone wrong.") );
channel.onClose( () => console.log("The channel has gone away gracefully") );


channel.join()
    .receive("ok", resp => { console.log("Okay, joined successfully"); })
    .receive("error", resp => { console.log("Unable to join", resp); });

export default socket;
