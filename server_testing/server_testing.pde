import processing.net.*;

int val = 0;
Server serv;

ArrayList history;

final int DRAW = 0;
final int MOVE = 1;
final int TIMERMOVE = 2;
final int SENDIMAGE = 3;
final int CHAT = 4;
final int RESET = 5;

void setup() {
  history = new ArrayList();
  
  size(100, 100);
  background(255);
  
  serv = new Server(this, 5402);

  fill(0);
  text("Server", 10, 30);

}

void draw() {  
  Client client = serv.available();
  if (client != null) {
    byte[] buffer = new byte[32];
    client.readBytes();
    history.add(buffer);
    serv.write(buffer);
  }
} 
