import processing.net.*;
import java.nio.ByteBuffer;
Client client;

void setup() {
  size(640,480);
  
  client = new Client(this, "127.0.0.1", 5402); 
  background(255);
  fill(0);
  text("Client", 10, 30);
}

void draw() {
  if (client.available() > 15) {
    byte[] buffer = new byte[4];
    client.readBytes(buffer);
    int x = btoi(buffer);
    client.readBytes(buffer);
    int y = btoi(buffer);
    client.readBytes(buffer);
    int px = btoi(buffer);
    client.readBytes(buffer);
    int py = btoi(buffer);
    line(x, y, px, py);
  }
  if (mousePressed) {
    byte[] buffer = new byte[16];
    ByteBuffer target = ByteBuffer.wrap(buffer);
    target.put(itob(mouseX));
    target.put(itob(mouseY));
    target.put(itob(pmouseX));
    target.put(itob(pmouseY));
    client.write(target.array());
  }
}

byte[] itob (int n) {
  return ByteBuffer.allocate(4).putInt(n).array(); 
}

int btoi (byte[] buffer)
{
  return ByteBuffer.wrap(buffer).getInt(); 
}

