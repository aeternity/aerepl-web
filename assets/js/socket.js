import {Socket} from "phoenix";

let socket = new Socket("/socket", {params: {token: window.userToken}});
socket.connect();

let channel         = socket.channel("repl_session:lobby", {});
let queryInput      = document.querySelector("#query-input");
let outputContainer = document.querySelector("#outputs");

var state;

queryInput.addEventListener("keypress", event => {
    if(event.keyCode === 13 && !event.shiftKey){
        let messageItem = document.createElement("li");
        messageItem.innerText = `${queryInput.value}`;
        messageItem.classList.add("in");
        outputContainer.appendChild(messageItem);

        channel.push("query", {input: queryInput.value.trim(),
                               state: state
                              });
        queryInput.value = "";
    }
});

channel.on("response", payload => {
    let messageItem = document.createElement("li");
    state = payload.state;

    if(payload.message !== "") {
        messageItem.innerText = `${payload.message}`;
        messageItem.classList.add("out");
        outputContainer.appendChild(messageItem);
    }
});

channel.onError( () => console.log("Something got wrong...") );
channel.onClose( () => console.log("The channel has gone away gracefully") );


channel.join()
    .receive("ok", resp => { console.log("Joined successfully"); })
    .receive("error", resp => { console.log("Unable to join", resp); });

export default socket;
