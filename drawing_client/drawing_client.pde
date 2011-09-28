import processing.net.*;
import java.nio.ByteBuffer;
Client client;


void setup() {
  size(800,600);
  smooth();
  client = new Client(this, "127.0.0.1", 5402); 
  background(255);
  fill(0);
  //text("Client", 10, 30);
  
  noStroke();
  colorMode(HSB, 150, 50, 100);
  for (int i = 0; i < 150; i++) {
    for (int j = 25; j < 50; j++) {
      stroke(i, j, 100);
      point(i, j-25);
    }
  }
  
}

void draw() {
  if (mousePressed) {
    if (colorSelected(mouseX, mouseY)) {
       stroke(getColor(mouseX, mouseY));
    } else {
       line(mouseX, mouseY, pmouseX, pmouseY); 
    }
  }
}

byte[] itob (int n) {
  return ByteBuffer.allocate(4).putInt(n).array(); 
}

int btoi (byte[] buffer)
{
  return ByteBuffer.wrap(buffer).getInt(); 
}

boolean colorSelected(int x, int y) {
  return x <= 150 && y <= 50;
}

color getColor(int x, int y) {
   return color(x,y+25,100); 
}



