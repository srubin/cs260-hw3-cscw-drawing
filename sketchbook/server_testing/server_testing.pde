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

void setup() {
  history = new ArrayList();
  size(100, 100); 
  //frameRate(100);
  oscP5 = new OscP5(this,listenPort);
  fill(0);
  text("Server", 10, 30);

  oscP5 = new OscP5(this,listenPort);
  oscP5.plug(this,"timer","/timer");
}

void draw() {
}

void oscEvent(OscMessage message) {
  if (message.isPlugged() == false) {
    if (message.addrPattern().equals("/server/connect")) {
      connect(message.netAddress().address());
      return;
    }
    if (message.addrPattern().equals("/server/disconnect")) {
      disconnect(message.netAddress().address());
      return;
    }
    // do not send move messages to their own client
    if (message.addrPattern() == "/move") {
       for(int i=0; i<listeners.size()-1; i++) {
         NetAddress client = listeners.get(i);
         if (client.address().equals(message.address())) { continue; }
         oscP5.send(message, client);
       }
    }
    oscP5.send(message, listeners);
    history.add(message);
  }
}

void timer(float position) {
  int lastToSend = int(history.size() * position);
  OscMessage clear = new OscMessage("/cleanStage");
  oscP5.send(clear, listeners);
  for (int i=0; i<lastToSend; i++) {
     oscP5.send((OscMessage)history.get(i), listeners);
  }
} 

void connect(String IP){
  if (!listeners.contains(IP, broadcastPort)) {
    listeners.add(new NetAddress(IP, broadcastPort));
    println("### "+IP+" now connected.");
  } else {
    println("### "+IP+" is already connected.");
  }
}

void disconnect(String IP) {
  if (listeners.contains(IP, broadcastPort)) {
    listeners.remove(IP, broadcastPort);
  } else {
    println("### "+IP+" is not connected.");
  }
}
