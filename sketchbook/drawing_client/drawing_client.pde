import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress drawServer;

int serverListenPort = 5402;
int myListenPort = 5403;

int id;
color localColor;
int localSize;

void setup() {
  size(800,600);
  frameRate(100);
  smooth();
  oscP5 = new OscP5(this, myListenPort);
  cleanStage();
  
  id = int(random(2^8));
  localColor = color(0);
  localSize = 1;
  
  drawServer = new NetAddress("127.0.0.1", serverListenPort);
  OscMessage message = new OscMessage("/server/connect");
  oscP5.flush(message, drawServer);
  
  oscP5.plug(this,"drawRemote","/draw");
  oscP5.plug(this,"moveRemote","/move");
  oscP5.plug(this,"chatRemote","/chat");
  oscP5.plug(this,"imageRemote","/image");
  oscP5.plug(this,"cleanStage","/cleanStage");
}

void cleanStage() {
  background(255);
  fill(255);
  rect(0,0,800,600);
  
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
  OscMessage message;
  
  if (mousePressed) {
    if (colorSelected(mouseX, mouseY)) {
       setColor(mouseX, mouseY);
       message = moveMessage();
    }
    else { message = drawMessage(); }
    if (false) { message = timerMessage(); }
  }
  else { message = moveMessage(); }
  
  if (false) { message = chatMessage(); }
  if (false) { message = imageMessage(); }

  oscP5.send(message, drawServer);
}

void drawRemote(int px, int py, int cx, int cy, color c, int brushSize) {
  stroke(c);
  line(mouseX, mouseY, pmouseX, pmouseY);
}

void moveRemote(int x, int y, color c, int brushsize, int id) {
  // stubbed 
}

void chatRemote(String chatstring) {
  // stubbed 
}

void imageRemote() {
  // pstubbed
}

OscMessage moveMessage() {
  OscMessage message = new OscMessage("/move");
  message.add(mouseX);
  message.add(mouseY);
  message.add(localColor);
  message.add(localSize);
  message.add(id);
  
  return message;
}

OscMessage drawMessage() {
  OscMessage message = new OscMessage("/draw");
  message.add(pmouseX);
  message.add(pmouseY);
  message.add(mouseX);
  message.add(mouseY);
  message.add(localColor);
  message.add(localSize);
  
  return message;
}

OscMessage timerMessage() {
  OscMessage message = new OscMessage("/timer");
  // note that the server expects timerPosition to be a float between 0 and 1
  //message.add(timerPosition);
  
  return message;
}

OscMessage chatMessage() {
  OscMessage message = new OscMessage("/chat");
  //message.add(chatString);
  
  return message;
}

OscMessage imageMessage() {
  OscMessage message = new OscMessage("/image");
  //message.add(imageData);
  
  return message;
}

boolean colorSelected(int x, int y) {
  return x <= 150 && y <= 50;
}

void setColor(int x, int y) {
   localColor = color(x,y+25,100);
}
