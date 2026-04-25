import socketio
BASE = "https://taxi-hbi9.onrender.com"
TOKEN = "eyJyb2xlIjoidXNlciIsInVpZCI6M30.aeorsA.6JlYPrZHT7Un1zWG2OvI1l30YAg"
CONV_ID = 2  # existing conversation_id
sio = socketio.Client(logger=True, engineio_logger=True)
@sio.event
def connect():
    print("connected")
    sio.emit("join_conversation", {"conversation_id": CONV_ID})
    sio.emit("send_message", {"conversation_id": CONV_ID, "text": "socket smoke test"})
@sio.on("joined_conversation")
def on_joined(data):
    print("joined_conversation:", data)
@sio.on("receive_message")
def on_receive(data):
    print("receive_message:", data)
    sio.disconnect()
@sio.on("error")
def on_error(data):
    print("socket error:", data)
sio.connect(BASE, auth={"token": TOKEN}, transports=["websocket"])
sio.wait()