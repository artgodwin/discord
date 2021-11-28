OscP5 oscP5;
NetAddress myRemoteLocation;


void startosc(int port) {
  
  /* start oscP5, listening for incoming messages at port 6000 */
  OscProperties properties = new OscProperties();
  properties.setDatagramSize(1536*2);
  properties.setListeningPort(port);
  oscP5 = new OscP5(this,properties);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
  //myRemoteLocation = new NetAddress("127.0.0.1",6001);

 /*
  * handlers for expected messages
  */
  oscP5.plug(this,"obC","/obC");
  oscP5.plug(this,"obP","/obP");
  oscP5.plug(this,"ob", "/ob");
  //oscP5.plug(this,"outl","/outl");
  oscP5.plug(this,"layout","/layout");
}


public Target targets(char ttype, int objID)
{
  switch(Character.toLowerCase(ttype)) {
    case 'u':
      return (objID >= targetsu.length) ? targetsu[0] : targetsu[objID];
    case 'r':
      return (objID >= targetsr.length) ? targetsr[0] : targetsr[objID];
    case 'l':
      return (objID >= targetsl.length) ? targetsl[0] : targetsl[objID];
  }  
  return  (objID >= targetsu.length) ? targetsu[0] : targetsu[objID];
}

// accept dimensions and alignment of scanners

public void layout(float sep, float offset, float left, float right) {

  println("### plug event method. received a message /layout.");
  println(millis()+" layout - left at "+left+", separation "+sep+", right at "+right);

  if (!freeze) {
    separation = sep;
    left_lidar_angle = degrees(left);
    right_lidar_angle = degrees(right);
 
  // offset not supported : line joining scanners defines baseline
  // float offset = offset;  // right scanner offset from left in Y, by this distance
  }
}

// cartesian coordinates
  
public void obC(char inst, int objID, float X, float Y, float cwidth, float pdepth) {
  //println("### plug event method. received a message /obC.");
  if (!freeze) {
    //println(" object "+objID+" at "+inst+", cartesian "+X+", "+Y);  
    if (inst == 'u')  {
      //println(" accept "+objID+" at "+inst+", cartesian "+X+", "+Y+" ("+cwidth+" x "+pdepth+")");  
      Target t = targets(inst,objID);
      t.X = X;
      t.Y = Y;
      t.cwidth = cwidth;
      t.pdepth = pdepth;
      t.alive  = true;
      t.zombie = !true;
      t.lastseen = millis();
      t.cdirty = true;   // polar corrdinates need updating
    }
  }
}

public void obP(char inst, int objID, float angle, float distance, float pwidth, float pdepth, int expiry) {
  //println("### plug event method. received a message /obP.");
  //println(" object at "+inst+", polar "+angle+", "+distance);  

 Target t = targets(inst,objID);
  if (!freeze) {
    t.angle = angle;
    t.dist = distance;
    t.pwidth = pwidth;
    t.pdepth = pdepth;
    t.alive = true;
    t.zombie = !true;
    t.lastseen = millis();
  }
}

public void ob(char inst, int objID, double birth, double lifetime, int alive, int valid, int zombie, String status) {
  //println("### plug event method. received a message /ob.");
  //println(" object "+objID+" ob-> at "+inst+", live for "+lifetime+", isalive "+alive+" status "+status);  

  Target t = targets(inst,objID);
  if (!freeze) {
    if (Character.toLowerCase(inst) == 'r') {
      t.alive = alive > 0;
      edger.text = status;
    }
    if (Character.toLowerCase(inst) == 'l') {
      targetsl[objID].alive = alive > 0;
      edgel.text = status;
    }
  //if (alive == 0)
    //println("target "+objID+" inst "+inst+" gone");
  }
}

/* incoming osc message are forwarded to the oscEvent method. */

void oscEvent(OscMessage theOscMessage) {
  
 if (freeze) {
   return;
 }

  /* print the address pattern and the typetag of the received OscMessage */
 if(theOscMessage.isPlugged()==false) {
   if(theOscMessage.checkAddrPattern("/outl")==true) {
     char source = theOscMessage.get(0).charValue(); 
     int count = theOscMessage.get(1).intValue(); 
     int start = theOscMessage.get(2).intValue(); 
     float inc = theOscMessage.get(3).floatValue();

     //println("outline received - "+count+" points starting at "+start+" from instance "+source+" at "+inc+"/point");

     if ((Character.toLowerCase(source) == 'r')
     && (start <= edger.edge)) {     
      for (int i = 0; i < count; ++i) {
        edger.border[i+start] = theOscMessage.get(i+4).floatValue();
        //println("ix "+ i + " =  " +border3[i]);
      }
      edger.inc = inc;
      edger.edge = max(edger.edge, count+start);

     } else if ((Character.toLowerCase(source) == 'l') 
     && (start <= edgel.edge)) {     
      for (int i = 0; i < count; ++i) {
        edgel.border[i+start] = theOscMessage.get(i+4).floatValue();
      }
      edgel.inc = inc;
      edgel.edge = max(edgel.edge, count+start);
     }

   } else if(theOscMessage.checkAddrPattern("/outb")==true) {
     char source = theOscMessage.get(0).charValue(); 
     int  count  = theOscMessage.get(1).intValue(); 
     int  start  = theOscMessage.get(2).intValue(); 
     float inc   = theOscMessage.get(3).floatValue();

     //println("raw outline received - "+count+" points starting at "+start+" from instance "+source+" at "+inc+"/point");
     if ((Character.toLowerCase(source) == 'r')
     && (start <= edger.back)) {
       for (int i = 0; i < count; ++i) {
         edger.backing[i+start] = theOscMessage.get(i+4).floatValue();
       }
      edger.back = max(edger.back, start+count);
     } else if ((Character.toLowerCase(source) == 'l') 
     && (start <= edgel.back)) {
      for (int i = 0; i < count; ++i) {
        edgel.backing[i+start] = theOscMessage.get(i+4).floatValue();
      }
      edgel.back = max(edgel.back, start+count);
     }
   } else {
    print("### received an unhandled message.");
    print(" addrpattern: "+theOscMessage.addrPattern());
    println(" typetag: "+theOscMessage.typetag());
   }
 }
}
