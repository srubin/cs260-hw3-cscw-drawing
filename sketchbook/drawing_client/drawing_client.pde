import oscP5.*;
import netP5.*;
import controlP5.*;

OscP5 oscP5;
NetAddress drawServer;
ControlP5 cp5;

int serverListenPort = 5402;
int myListenPort = 5403;

int id;
color localColor;
int localSize = 5;
float historyPosition = 1.0;
boolean eraseOn = false;

ControlFont menlo;
PGraphics canvas;

void setup() {
  size(800,600);
  background(255);
  fill(0);
  //frameRate(100);
  smooth();
  oscP5 = new OscP5(this, myListenPort);
  
  id = int(random(2^16-1));
  localColor = color(0);
  
  drawServer = new NetAddress("127.0.0.1", serverListenPort);
  OscMessage message = new OscMessage("/server/connect");
  oscP5.flush(message, drawServer);
  
  oscP5.plug(this,"drawRemote","/draw");
  oscP5.plug(this,"cleanStage","/cleanStage");
  
  noStroke();
  colorMode(HSB, 150, 50, 100);
  for (int i = 0; i < 150; i++) {
    for (int j = 25; j < 50; j++) {
      stroke(i, j, 100);
      point(i+10, j-15);
    }
  }
  cp5 = new ControlP5(this);
  cp5.addSlider("localSize",1,50,localSize,10,45,150,25).setCaptionLabel("Brush size");
  cp5.addSlider("historyPosition",0.0,1.0,historyPosition,10,115,150,25).setCaptionLabel("History");
  cp5.addButton("imageButton",0,10,150,150,25).setCaptionLabel("Add image");
  cp5.addToggle("eraseOn",false,10,80,150,25).setCaptionLabel("Erase");
  stylePurple(cp5.controller("eraseOn"), "toggle");
  stylePurple(cp5.controller("localSize"),"slider");
  stylePurple(cp5.controller("historyPosition"),"slider");
  stylePurple(cp5.controller("imageButton"),"button");
  
  canvas = createGraphics(630,600,JAVA2D);
  canvas.beginDraw();
  canvas.smooth();
  canvas.endDraw();
}

void cleanStage() {
  canvas.beginDraw();
  canvas.fill(#ffffff);
  canvas.noStroke();
  canvas.rect(0,0,630,600);
  canvas.endDraw();
}

void draw() {
  OscMessage message;
  
  if (mousePressed) {
    if (colorSelected(mouseX, mouseY)) {
       setColor(mouseX, mouseY);
       message = moveMessage();
    }
    else if (inDrawingArea(mouseX, mouseY)) {
       message = drawMessage();
    }
    else {
       message = moveMessage(); 
    }
    if (false) { message = timerMessage(); }
  }
  else { 
    message = moveMessage(); 
  }
  
  if (false) { message = chatMessage(); }
  if (false) { message = imageMessage(); }

  oscP5.send(message, drawServer);
}

void oscEvent(OscMessage message) {
  println("### received an osc message with addrpattern "+message.addrPattern()+" and typetag "+message.typetag());
  message.print(); 
}

void drawRemote(int px, int py, int cx, int cy, color c, int brushSize) {
  canvas.beginDraw();
  canvas.strokeWeight = brushSize;
  canvas.stroke(c);
  canvas.line(cx, cy, px, py);
  canvas.endDraw();
  image(canvas, 170, 0);
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
  message.add(pmouseX-170);
  message.add(pmouseY);
  message.add(mouseX-170);
  message.add(mouseY);
  message.add(eraseOn ? color(#ffffff) : localColor);
  message.add(localSize);
  
  return message;
}

OscMessage timerMessage() {
  OscMessage message = new OscMessage("/timer");
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
  //message.add(url);
  //message.add(imageData);
  
  return message;
}

boolean colorSelected(int x, int y) {
  return x <= 150 && y <= 50;
}

void setColor(int x, int y) {
  localColor = color(x-10,y+15,100);
}

boolean inDrawingArea(int x, int y) {
  return x >= 170; 
}

void stylePurple(Controller c, String t) {
  ControlFont menlo = new ControlFont(loadFont("Menlo-Regular-12.vlw"));
  c.setColorBackground(color(#777777));
  c.setColorForeground(color(#663366));
  c.setColorActive(color(#CC33CC));
  c.setColorValueLabel(color(#ffffff));
  c.setColorCaptionLabel(color(#ffffff));
  c.valueLabel().setControlFont(menlo);
  int len = c.captionLabel().toString().length();
  if (t == "slider") {
    c.captionLabel().style().marginLeft = -(7*len+10);
  } else if (t == "button") {
    c.captionLabel().style().marginLeft = 140-7*len;
  } else if (t == "toggle") {
    c.captionLabel().style().marginLeft = 142-7*len;
    c.captionLabel().style().marginTop = -20;
  }
  c.captionLabel().setControlFont(menlo);
}
