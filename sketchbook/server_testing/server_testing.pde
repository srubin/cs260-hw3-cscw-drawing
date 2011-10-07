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

void setup() {
  background(255);
  size(100, 100); 
  //frameRate(1);
  OscProperties props = new OscProperties();
  props.setListeningPort(listenPort);
  props.setDatagramSize(100000);
  oscP5 = new OscP5(this,props);
  oscP5.plug(this,"timer","/timer");
  oscP5.plug(this,"timerReset","/timerReset");
  
  fill(0);
  text("Server", 10, 30);
}

void draw() { }

void oscEvent(OscMessage message) {
  if (!message.isPlugged()) {
    if (message.addrPattern().equals("/server/connect")) {
      connect(message.netAddress().address());
      return;
    }
    if (message.addrPattern().equals("/server/disconnect")) {
      disconnect(message.netAddress().address());
      return;
    }
    
    if (message.checkAddrPattern("/image")) {
      println("Got image message on server"); 
    }
    
    // do not send move messages to their own client
    if (message.checkAddrPattern("/move")) {
       for(int i=0; i<listeners.size(); i++) {
         NetAddress client = listeners.get(i);
         if (!("/" + client.address()).equals(message.address())) {
           oscP5.send(message, client);
         }
       }
    } else {
      oscP5.send(message, listeners);
    }
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
