import processing.net.*;

int val = 0;
Server serv;

void setup() {
  size(100, 100);
  background(255);
  
  serv = new Server(this, 5402);

  fill(0);
  text("Server", 10, 30);

}

void draw() {  
  stroke(0);

  Client client = serv.available();
  if (client != null) {
    byte[] buffer = new byte[16];
    client.readBytes(buffer);
    serv.write(buffer);
  }
} 
