
const readline = require('readline');

// Config
const SERVER_URL = process.env.SERVER_URL || "http://127.0.0.1:8787";
const CONNECTION_KEY = process.env.KEY || "my-secret-password";
const SENDER_NAME = process.env.NAME || "OpenClaw-Bot";
const SENDER_ID = "bot-" + Math.random().toString(36).substr(2, 9);

console.log(`
🤖 OpenClaw Integration Demo
----------------------------
Server: ${SERVER_URL}
Key:    ${CONNECTION_KEY}
Name:   ${SENDER_NAME}
----------------------------
Listening for messages... (Type to reply)
`);

// Polling Loop
let lastId = 0;

async function pollMessages() {
  while (true) {
    try {
      const response = await fetch(`${SERVER_URL}/poll?last_id=${lastId}`, {
        headers: { "x-connection-key": CONNECTION_KEY }
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${await response.text()}`);
      }
      
      const messages = await response.json();
      
      if (Array.isArray(messages)) {
        for (const msg of messages) {
          // Skip own messages
          if (msg.sender_id !== SENDER_ID) {
            console.log(`\n[${msg.sender_name}]: ${msg.content}`);
            process.stdout.write("> "); // Prompt
          }
          
          if (msg.id > lastId) {
            lastId = msg.id;
          }
        }
      }
    } catch (error) {
      console.error("\n[Error] Polling failed:", error.message);
      await new Promise(r => setTimeout(r, 5000));
    }
  }
}

// Sending Logic
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.on('line', async (input) => {
  if (!input.trim()) return;
  
  try {
    const payload = {
      senderName: SENDER_NAME,
      senderID: SENDER_ID,
      content: input,
      id: crypto.randomUUID(),
      type: "text"
    };

    const response = await fetch(`${SERVER_URL}/send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-connection-key": CONNECTION_KEY
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      console.error(`[Error] Send failed: ${await response.text()}`);
    } else {
      process.stdout.write("> ");
    }
  } catch (e) {
    console.error(`[Error] Send failed: ${e.message}`);
  }
});

// Start
process.stdout.write("> ");
pollMessages();
