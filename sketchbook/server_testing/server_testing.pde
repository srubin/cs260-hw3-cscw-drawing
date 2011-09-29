/**
 *  Much of the code for this server comes from the examples for OSC,
 *  which can be found at the OSC website:
 *
 *  http://www.sojamo.de/oscP5
 *
*/

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddressList listeners = new NetAddressList();
int listenPort = 5402;
int broadcastPort = 5403;

ArrayList history;

String connectPattern = "/server/connect";
String disconnectPattern = "/server/disconnect";

void setup() {
  history = new ArrayList();
  size(100, 100); 
  //frameRate(100);
  oscP5 = new OscP5(this,listenPort);
  fill(0);
  text("Server", 10, 30);
}

void draw() {

} 

void oscEvent(OscMessage message) {
  /* check if the address pattern fits any of our patterns */
  if (message.addrPattern().equals(connectPattern)) {
    connect(message.netAddress().address());
  }
  else if (message.addrPattern().equals(disconnectPattern)) {
    disconnect(message.netAddress().address());
  }
  else {
    oscP5.send(message, listeners);
    history.add(message);
  }
}

private void connect(String IP) {
  if (!listeners.contains(IP, broadcastPort)) {
    listeners.add(new NetAddress(IP, broadcastPort));
    println("### "+IP+" now connected.");
  } else {
    println("### "+IP+" is already connected.");
  }
}



private void disconnect(String IP) {
  if (listeners.contains(IP, broadcastPort)) {
    listeners.remove(IP, broadcastPort);
  } else {
    println("### "+IP+" is not connected.");
  }
}
