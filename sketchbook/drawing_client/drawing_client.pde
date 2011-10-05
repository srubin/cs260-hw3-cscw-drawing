import oscP5.*;
import netP5.*;
import controlP5.*;
import java.awt.image.BufferedImage;
import javax.imageio.*;
import java.util.regex.Pattern;

OscP5 oscP5;
NetAddress drawServer;
NetAddress me;
ControlP5 cp5;

int serverListenPort = 5402;
int myListenPort = 5403;

int id;
color localColor;
int localSize = 5;
float historyPosition = 1.0;
HistoryListener historyListener;
boolean eraseOn = false;
boolean reset = false;

PImage  img;
OscMessage imgMsg;
boolean imgPosition = false;

ControlFont menlo;
PGraphics canvas;
PGraphics ghosts;
Textarea chat;

List history;
boolean inThePast = false;
int lastToReplay = -1;
boolean drawFromHistory = true;

void setup() {
  history = new ArrayList();
  
  size(800,600);
  background(255);
  fill(0);
  frameRate(30); // prevents the server from freaking out
  smooth();
  
  OscProperties props = new OscProperties();
  props.setListeningPort(myListenPort);
  props.setDatagramSize(100000);
  oscP5 = new OscP5(this, props);
  
  id = int(random(1<<8));
  localColor = color(0);
  
  //drawServer = new NetAddress("128.32.44.58", serverListenPort);
  drawServer = new NetAddress("127.0.0.1", serverListenPort);
  OscMessage message = new OscMessage("/server/connect");
  oscP5.flush(message, drawServer);
  
  me = new NetAddress("127.0.0.1", myListenPort);
  
  oscP5.plug(this,"drawRemote","/draw");
  oscP5.plug(this,"moveRemote","/move");
  oscP5.plug(this,"chatRemote","/chat");
  oscP5.plug(this,"imageRemote","/image");
  oscP5.plug(this,"timerRemote","/timer");
  oscP5.plug(this,"cleanStage","/cleanStage");
  oscP5.plug(this,"timerReset","/timerReset");
  
  cp5 = new ControlP5(this);
  cp5.addSlider("localSize",1,50,localSize,10,45,150,25).setCaptionLabel("Brush size");
  cp5.addSlider("historyPosition",0.0,1.0,historyPosition,10,115,150,25).setCaptionLabel("History");
  cp5.addButton("imageButton",0,10,150,150,25).setCaptionLabel("Add image");
  cp5.addToggle("eraseOn",false,90,80,70,25).setCaptionLabel("Eraser");
  cp5.addButton("clean",0,10,80,70,25).setCaptionLabel("Clear");
  cp5.addTextfield("chatEntry",10,565,780,25);
  
  cp5.addTextarea("chatDisplay","Chat",10,185,140,370);
  chat = (Textarea)cp5.getGroup("chatDisplay");
  chat.valueLabel().setFont(ControlP5.grixel);
  chat.setColor(#000000);
  
  stylePurple(cp5.controller("chatEntry"), "toggle");
  stylePurple(cp5.controller("eraseOn"), "toggle");
  stylePurple(cp5.controller("localSize"),"slider");
  stylePurple(cp5.controller("historyPosition"),"slider");
  stylePurple(cp5.controller("imageButton"),"button");
  stylePurple(cp5.controller("clean"),"");
  
  historyListener = new HistoryListener();
  cp5.controller("historyPosition").addListener(historyListener);
  ((Slider)cp5.controller("historyPosition")).setNumberOfTickMarks(11);
  
  cp5.controller("eraseOn").captionLabel().style().marginTop = -20;
  cp5.controller("eraseOn").captionLabel().style().marginLeft = 62-7*"eraser".length();
  
  canvas = createGraphics(630,600,JAVA2D);
  canvas.beginDraw();
  canvas.smooth();
  canvas.background(#ffffff);
  canvas.endDraw();
  
  ghosts = createGraphics(800,600,JAVA2D);
  ghosts.beginDraw();
  ghosts.smooth();
  ghosts.endDraw();
}

void oscEvent(OscMessage message) {
  if (message.checkAddrPattern("/cleanStage") ||
      message.checkAddrPattern("/draw") ||
      message.checkAddrPattern("/image")) {
        // these are the only kinds of messages we want to store
        if (inThePast) {
          inThePast = false;
          history = history.subList(0, lastToReplay);
          timerReset();
          history.add(createLocalMessage(message));
        } else {
          history.add(createLocalMessage(message)); 
        }
  }
}

void replayHistoryToPosition(float position) {
  lastToReplay = (int)(position * history.size());
  cleanStage();
  for(int i = 0; i < lastToReplay; i++) {
    Doer localAction = (Doer)history.get(i);
    localAction.doAction();
    //println("redid message number " + str(i));
  }
}

void clean() {
  OscMessage message = new OscMessage("/cleanStage");
  oscP5.send(message, drawServer);
}

void imageButton() {
  String imageLocation = selectInput("Choose an image file (png, gif, tga, jpg)");
  if (imageLocation != null) {
    if (imageLocation.matches(".*(png|gif|tga|jpg|jpeg)$")) {
      img = loadImage(imageLocation);
      byte[] imageData = loadBytes(imageLocation); 
      imgMsg = new OscMessage("/image");  
      byte[] imgBlob = OscMessage.makeBlob(imageData);
      imgMsg.add(imgBlob);
      imgPosition = true;
    }
  }
}

void cleanStage() {
  canvas.beginDraw();
  canvas.background(#ffffff);
  canvas.endDraw();
  image(canvas,170,0);
}

void draw() {
  if (drawFromHistory) {
    replayHistoryToPosition(cp5.controller("historyPosition").value());
    drawFromHistory = false;
  }
  
  OscMessage message;

  background(#ffffff);
  noStroke();
  colorMode(HSB, 150, 50, 100);
  for (int i = 0; i < 150; i++) {
    for (int j = 25; j < 50; j++) {
      stroke(i, j, 100);
      point(i+10, j-15);
    }
  }
  colorMode(ARGB);
  fill(0);
  noStroke();
  rect(10,0,75,10);
  
  fill(localColor);
  noStroke();
  rect(85,0,75,10);
  
  if (mousePressed && imgPosition) {
    canvas.beginDraw();
    canvas.image(img, mouseX-170, mouseY);
    canvas.endDraw();
    image(canvas,170,0); 
    imgPosition = false;
    imgMsg.add(mouseX-170);
    imgMsg.add(mouseY);
    message = imgMsg;
  } else if (mousePressed) {
    if (colorSelected(mouseX, mouseY)) {
       setColor(mouseX, mouseY);
       message = moveMessage();
    }
    else if (inDrawingArea(mouseX, mouseY)) {
       message = drawMessage();
       drawRemote(pmouseX-170, pmouseY, mouseX-170, mouseY, eraseOn ? color(#ffffff) : localColor, localSize);
    }
    else {
       message = moveMessage(); 
    }
  }
  else { 
    message = moveMessage(); 
  }
  
  if (false) { message = chatMessage("192.168.1.1","i am not a robot, i am a unicorn."); }

  oscP5.send(message, drawServer);
  
  image(canvas, 170, 0);
  image(ghosts,0,0);
}

void drawRemote(int px, int py, int cx, int cy, color c, int brushSize) {
  canvas.beginDraw();
  canvas.strokeWeight(brushSize);
  canvas.stroke(c);
  canvas.line(cx, cy, px, py);
  canvas.endDraw();
}

void moveRemote(int x, int y, color c, int brushsize, int id) {
  ghosts.beginDraw();
  ghosts.background(0,0);
  ghosts.noStroke();
  ghosts.fill(c);
  ghosts.ellipse(x,y,brushsize,brushsize); 
  ghosts.endDraw();
}

void chatRemote(String ip, String chatstring) {
  chat.setText(chat.text() + "\n\n" + ip + ": " + chatstring);
  chat.scroll(1.0);
}

void imageRemote(byte[] imgBytes, int x, int y) {
  PImage pim = getAsImage(subset(imgBytes,4));
  canvas.beginDraw();
  canvas.image(pim,x,y);
  canvas.endDraw();
  image(canvas,170,0);
}

// this method is from the web
public PImage getAsImage(byte[] imgBytes) {
  try {
    ByteArrayInputStream bis=new ByteArrayInputStream(imgBytes); 
    BufferedImage bimg = ImageIO.read(bis); 
    PImage img=new PImage(bimg.getWidth(),bimg.getHeight(),PConstants.ARGB);
    bimg.getRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);
    img.updatePixels();
    return img;
  }
  catch(Exception e) {
    System.err.println("Can't create image from buffer");
    e.printStackTrace();
  }
  return null;
}

void timerRemote(float position) {
  println("got timerRemote at " + position);
  drawFromHistory = true;
  //replayHistoryToPosition(position);
  cp5.controller("historyPosition").setValue(position);
}

void timerReset() {
  println("Timer reset on client end");
  reset = true;
  cp5.controller("historyPosition").setValue(1.0);
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

OscMessage timerMessage(float val) {
  OscMessage message = new OscMessage("/timer");
  message.add(val);
  inThePast = (val == 1.0) ? false : true;
  
  return message;
}

OscMessage chatMessage(String ip, String chatString) {
  OscMessage message = new OscMessage("/chat");
  message.add(ip);
  message.add(chatString);
  
  return message;
}

boolean colorSelected(int x, int y) {
  return (x >= 10 && x <= 160 && y <= 35 && y >= 10) 
    || (x >=10 && x <= 85 && y <= 10);
}

void setColor(int x, int y) {
  if (x >= 10 && x <= 85 && y <= 10) {
    localColor = color(#000000);
  } else {
    colorMode(HSB, 150, 50, 100);
    localColor = color(x-10,y+15,100);
    colorMode(ARGB);
  }
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
  }
  c.captionLabel().setControlFont(menlo);
}

void chatEntry(String t) {
  OscMessage message = chatMessage(oscP5.ip(),t);
  oscP5.send(message, drawServer);
}

class HistoryListener implements ControlListener {
  float oldHist = 1.0;
  public void controlEvent(ControlEvent e) {
    if (abs(oldHist-e.controller().value()) >= .1 && !reset) { 
      println("new: " +e.controller().value() + " old:" + oldHist);
      oscP5.send(timerMessage(e.controller().value()), drawServer);
      oldHist = e.controller().value();
    } else if (reset) {
      oldHist = 1.0;
      reset = false;
    } 
  }
}

interface Doer {
  void doAction();
}

class LocalDrawMessage implements Doer {
  int prevMouseX;
  int prevMouseY;
  int curMouseX;
  int curMouseY;
  color drawColor;
  int drawSize;
  
  LocalDrawMessage(int prevMouseX, int prevMouseY, int curMouseX, int curMouseY, color drawColor, int drawSize) {
    this.prevMouseX = prevMouseX;
    this.prevMouseY = prevMouseY;
    this.curMouseX = curMouseX;
    this.curMouseY = curMouseY;
    this.drawColor = drawColor;
    this.drawSize = drawSize;
  }
  
  void doAction() {
    drawRemote(prevMouseX, prevMouseY, curMouseX, curMouseY, drawColor, drawSize);
    /*canvas.beginDraw();
    canvas.strokeWeight(drawSize);
    canvas.stroke(drawColor);
    canvas.line(curMouseX, curMouseY, prevMouseX, prevMouseY);
    canvas.endDraw();
    image(canvas,170,0);*/
  }
}

class LocalClearMessage implements Doer {
  LocalClearMessage() {}

  void doAction() {
    cleanStage();
    /*canvas.beginDraw();
    canvas.background(#ffffff);
    canvas.endDraw();
    image(canvas,170,0);*/ 
  }
}

class LocalImageMessage implements Doer {
  byte[] imgData;
  int x;
  int y;
  LocalImageMessage(byte[] img, int x, int y) {
    this.imgData = img;
    this.x = x;
    this.y = y;
  } 
  void doAction() {
    imageRemote(imgData,x,y);
  }
}

Doer createLocalMessage(OscMessage message) {
  Doer retVal = null;

  if (message.checkAddrPattern("/draw")) {
    retVal = new LocalDrawMessage(message.get(0).intValue(), message.get(1).intValue(), message.get(2).intValue(),
                                  message.get(3).intValue(), message.get(4).intValue(), message.get(5).intValue());
  }
  if (message.checkAddrPattern("/cleanStage")) {
    retVal = new LocalClearMessage(); 
  }
  if (message.checkAddrPattern("/image")) {
    retVal = new LocalImageMessage(message.get(0).blobValue(), message.get(1).intValue(), message.get(2).intValue());
  }
  return retVal;
}
