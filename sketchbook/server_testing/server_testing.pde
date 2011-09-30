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

boolean inThePast = false;
int lastToSend;
int lastPosition = -1;

List history;

void setup() {
  history = new ArrayList();
  background(255);
  size(100, 100); 
  //frameRate(1);
  oscP5 = new OscP5(this,listenPort);
  oscP5.plug(this,"timer","/timer");
  oscP5.plug(this,"timerReset","/timerReset");
  
  fill(0);
  text("Server", 10, 30);
}

void draw() {

}

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
    // do not send move messages to their own client
    if (message.addrPattern().equals("/move")) {
       for(int i=0; i<listeners.size(); i++) {
         NetAddress client = listeners.get(i);
         if (!("/" + client.address()).equals(message.address())) {
           oscP5.send(message, client);
         }
       }
    } else {
      oscP5.send(message, listeners);
    }
    if (!inThePast && !message.addrPattern().equals("/move")) {
      history.add(message);
    } else if (inThePast) {
      if (message.addrPattern().equals("/draw")) {
        
        // we only re-start keeping track of history when new drawings are put down
        inThePast = false;
        lastPosition = 0;
        history = history.subList(0, lastToSend);
        OscMessage resetToPresent = new OscMessage("/timerReset");
        //resetToPresent.add(1.0);
        oscP5.send(resetToPresent, listeners);
      } 
    }
  }
}

void timerReset() {
  println("timer reset on server");
}

void timer(float position) {
  println("timer event on server at " + position);
  lastToSend = int(history.size() * position);

  if (lastPosition > lastToSend || lastPosition == -1) {
    lastPosition = 0;
    OscMessage clear = new OscMessage("/cleanStage");
    oscP5.send(clear, listeners); 
  }
  
  for (int i=lastPosition; i<lastToSend; i++) {
     oscP5.send((OscMessage)history.get(i), listeners);
  }
  if (position < 1.0) {
    inThePast = true;
  } else {
    inThePast = false;
  }
  lastPosition = lastToSend;
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
