import processing.net.*;
import java.nio.ByteBuffer;
Client client;

int id;
color localColor;
int localSize;

final int DRAW = 0;
final int MOVE = 1;
final int TIMERMOVE = 2;
final int SENDIMAGE = 3;
final int CHAT = 4;
final int RESET = 5;

void setup() {
  size(800,600);
  smooth();
  client = new Client(this, "127.0.0.1", 5402); 
  background(255);
  fill(0);
  
  noStroke();
  colorMode(HSB, 150, 50, 100);
  for (int i = 0; i < 150; i++) {
    for (int j = 25; j < 50; j++) {
      stroke(i, j, 100);
      point(i, j-25);
    }
  }
  
  id = int(random(2^16-1));
  localColor = color(0);
  localSize = 1;
}

void draw() {
  byte[] buffer = new byte[32];
  ByteBuffer message = ByteBuffer.wrap(buffer);
  if (mousePressed) {
    if (colorSelected(mouseX, mouseY)) {
       getColor(mouseX, mouseY);
       stroke(localColor);
       message = moveMessage(message);
    }
    else {
       stroke(localColor);
       line(mouseX, mouseY, pmouseX, pmouseY); 
       message = drawMessage(message);
    }
    if (false) {
       message = timerMessage(message);
    }

  }
  else {
    message = moveMessage(message);
  }
  
  if (false) {
    message = chatMessage(message);
  }
  if (false) {
    message = imageMessage(message);
  }
  
  client.write(message.array());
}

ByteBuffer moveMessage(ByteBuffer message) {
  message.clear();
  message.put(itob(MOVE));
  message.put(itob(mouseX));
  message.put(itob(mouseY));
  message.put(itob(pmouseX));
  message.put(itob(pmouseY));
  message.put(colortob(localColor));
  message.put(itob(localSize));
  message.put(itob(id));
  
  return message;
}

ByteBuffer drawMessage(ByteBuffer message) {
  message.clear();
  message.put(itob(DRAW));
  message.put(itob(mouseX));
  message.put(itob(mouseY));
  message.put(itob(pmouseX));
  message.put(itob(pmouseY));
  message.put(colortob(localColor));
  message.put(itob(localSize));
  
  return message;
}

ByteBuffer timerMessage(ByteBuffer message) {
  message.clear();
  message.put(itob(1));
  
  return message;
}

ByteBuffer chatMessage(ByteBuffer message) {
  message.clear();
  message.put(itob(1));
  
  return message;
}

ByteBuffer imageMessage(ByteBuffer message) {
  message.clear();
  message.put(itob(1));
  
  return message;
}

byte[] itob (int n) {
  return ByteBuffer.allocate(4).putInt(n).array(); 
}

byte[] colortob (color c) {
  return ByteBuffer.allocate(4).putInt(c).array();
}

int btoi (byte[] buffer) {
  return ByteBuffer.wrap(buffer).getInt(); 
}

color btocolor(byte[] buffer) {
  int casi = ByteBuffer.wrap(buffer).getInt();
  int a = (casi >> 24) & 0xFF;
  int r = (casi >> 16) & 0xFF;
  int g = (casi >> 8) & 0xFF;
  int b = casi & 0xFF;
  return color(r, g, b, a);
}

boolean colorSelected(int x, int y) {
  return x <= 150 && y <= 50;
}

color getColor(int x, int y) {
   localColor = color(x,y+25,100);
   return localColor;
}
