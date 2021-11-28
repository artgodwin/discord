int NUMRAWTARGETS = 20;  // target structures per input source
int NUMTARGETS = 4;      // targets in view

class Target {
  // location & size
  float X;  // offset from scanner centre as received
  float Y;
  float displayX;  // offset from map centre as required for normalised midi
  float displayY;
  float dist;
  float angle;
  float pwidth;
  float cwidth;
  float pdepth;
  float lastX;
  float lastY;
  float speed;
  long  update;
  // status & history
  long birth;
  long lifetime;
  long lastseen;
  boolean inuse;
  boolean valid;
  boolean alive;
  boolean zombie;
  boolean cdirty;
  String status;
  boolean frozen;
  boolean hidden;
  // relationships
  int   nearest;
  float nearest_distance;
  float nearest_bearing;
  float crowding;
  
 Target() {
    X = 0;
    Y = 0;
    lastX = 0;
    lastY = 0;
    update = 0;
    dist = 0;
    angle = 0;
    birth = 0;
    lifetime = 0;
    inuse = !true;
    valid = !true;
    alive = !true;
    zombie = !true;
    nearest = -1;
    nearest_distance = 0.0;
    nearest_bearing = 0.0;
    crowding = 0.0;
 }

  boolean isAlive() {
    return alive && !zombie;
  }
}

Target[] targetsr;
Target[] targetsl;
Target[] targetsu;

void starttargets() {
  targetsr = new Target[NUMRAWTARGETS];
  for(int i = 0; i < targetsr.length; ++i)
    targetsr[i] = new Target();

  targetsl = new Target[NUMRAWTARGETS];
  for(int i = 0; i < targetsl.length; ++i)
    targetsl[i] = new Target();

  targetsu = new Target[NUMTARGETS];
  for(int i = 0; i < targetsu.length; ++i)
    targetsu[i] = new Target();
}    

void cleartargets() 
{
  for(int i = 0; i < targetsr.length; ++i)
    targetsr[i].alive = !true;

  for(int i = 0; i < targetsl.length; ++i)
    targetsl[i].alive = !true;

  for(int i = 0; i < targetsu.length; ++i)
    targetsu[i].alive = !true;
}


// draw the targets seen by the sensor using the sensor's own polar coordinates

void drawtargetsP( Target[] targets, float tranx, float trany, float trangle, color colour, boolean solid, char inst)
{
  pushMatrix();
  translate(tranx, trany);
  rotate(radians(trangle));
  
  for(int i = 0; i < targets.length; ++i) {

    if (targets[i].isAlive()) {

      if (!freeze) {
        if ((millis() - targets[i].lastseen) > overaged) {
          targets[i].zombie = true;
          //println("target "+i+" from "+inst+" expired");
        }
      }

      // target not confirmed - paint it grey
      if (targets[i].zombie) {
        colour = czombie;
      }

      float dist = targets[i].dist*dscale;
      float size = dist * sin(radians(targets[i].pwidth));
      if (size > 60) {
        //println("clipped "+size+" to 60");
        size = 60;
      }
      // SIGN CHANGE in angle
      float angle = radians(180-targets[i].angle); 
      float aura = targets[i].crowding*size;
      // clip magnification to avoid splatting the whole screen
      if (aura > (4*size))
        aura = 4*size;
      
      //println(" target "+inst+" "+i+" alive "+targets[i].alive+" at "+targets[i].angle+" deg, "+targets[i].dist+" m ("+dist+" px) size "+size+" crowd "+aura);
      noStroke();
      pushMatrix();
      translate(dist*cos(angle), dist*sin(angle));
      if (aura > size) {
        fill(caura);
        ellipse(0,0,aura,aura);
      }
      fill(colour);
      ellipse(0,0,size,size);
      //println("ellipse P"+i+" at "+targets[i].dist*cos(radians(targets[i].angle))+", "+targets[i].dist*sin(radians(targets[i].angle))
      //      +" size "+size+" ("+targets[i].dist*sin(radians(targets[i].pwidth))+" x "+targets[i].pdepth+")");
      // next text or blob in black
      fill(0);
      if (!solid) {
        // make black hole
        ellipse(0,0,size-3,size-3);
        // but put text colour back
        fill(colour);
      }
      textAlign(RIGHT);
      rotate(-radians(trangle));
      textSize(16);
      text(i+1,4,8);
      fill(colour);  // put linked object text size back too
      
      // show bearings of objects ref scanner
      if (coords) {
        if (inst == 'l') {
          text(nf(targets[i].dist,2,2),(textsize*-3)+size, textsize*0);
          text(nf(targets[i].angle,2,2),(textsize*-3)+size, textsize*1);
        } else if (inst == 'r') {
          text(nf(targets[i].dist,2,2),(textsize*3)+size, textsize*0);
          text(nf(targets[i].angle,2,2),(textsize*3)+size, textsize*1);
        } else { // combined
          text(nf(targets[i].dist,2,2),textsize*2, textsize*2);
          text(nf(targets[i].angle,2,2),textsize*2, textsize*3);
        }
      }
      popMatrix();
    }  
  }
  popMatrix();
}

// draw the targets remapped into a common cartesian coordinate systemn

void drawtargetsC( Target[] targets, float centreX, float centreY, color colour, boolean solid, char inst)
{
  pushMatrix();
  translate(centreX, centreY);

  for(int i = 0; i < targets.length; ++i) {
    if (targets[i].isAlive()) {
  
      if ((millis() - targets[i].lastseen) > overaged) {
        targets[i].zombie = true;
        //println("target "+i+" from "+inst+" expired");
      }
      
      float X = targets[i].X*dscale;
      // SIGN CHANGE in Y direction
      float Y = -targets[i].Y*dscale;
      float size = targets[i].cwidth*dscale;

      pushMatrix();
      //println("target "+i+" alive "+targets[i].alive+" at "+targets[i].X+", "+targets[i].dist+" size "+targets[i].cwidth);
      fill(colour);
      noStroke();
      translate(X,Y);
      ellipse(0,0,size,size);
      //println("ellipse C"+i+" at "+targets[i].X+", "+targets[i].Y
      //      +" size "+size+" ("+targets[i].cwidth+" x "+targets[i].pdepth+")");
      fill(0);
      if (!solid) {
        ellipse(0,0,size-3,size-3);
        fill(colour);
      }
      textAlign(RIGHT);
      textSize(16);
      text(i+1,4,8);
      popMatrix();
    }  
  }
  popMatrix();
}

// check to see if any targets are clicked on during hide or move

void testtargetsC( Target[] targets, float refX, float refY) 
{
  pushMatrix();
  translate(refX, refY);

  for(int i = 0; i < targets.length; ++i) {
    if (targets[i].isAlive()) {
  
      int X = (int)(targets[i].X*dscale);
      // SIGN CHANGE in Y direction
      int Y = -(int)(targets[i].Y*dscale);
      int size = (int)(targets[i].cwidth*dscale);
      
      // hide a target ?
      if (hiding & (testmouse(X,Y,size/2))) {
        targets[i].hidden = !targets[i].hidden;
      }

      // manual control of target ?
      if (move & (testmouse(X,Y,size/2))) {
        targets[i].frozen = !targets[i].frozen;
      }
    }  
  }
  popMatrix();
}


void updatederived(Target[] t, float xoffset, float yoffset, float angleoffset)
{
  float dist, angle, X, Y;
  
  for(int i = 0; i < t.length; ++i) {
    if (t[i].cdirty) {
      t[i].cdirty = !true;
      X = t[i].X + xoffset/dscale;
      Y = t[i].Y + yoffset/dscale;
      dist = sqrt(X*X+Y*Y);
      angle = (X > 0) ? 180 - degrees(asin( -Y/dist )) : degrees(asin( -Y/dist )); 
      t[i].dist   = dist;
      t[i].angle  = angle + angleoffset;
      t[i].pwidth = 2 * degrees(asin(t[i].cwidth/(2*dist)));
      //print("convert "+i+", from "+X+", "+Y+" ("+t[i].cwidth+" x "+t[i].pdepth+")");
      //println(" --> "+t[i].dist+" m  at "+t[i].angle+" deg ("+t[i].pwidth+" x "+t[i].pdepth+")" );  
    }
    
    // calculate resultant speed
    if (t[i].alive) { 
      if (t[i].update > 0) {
        float vX = t[i].X-t[i].lastX;
        float vY = t[i].Y-t[i].lastY;
        float vS = 1000.0*(float)Math.sqrt((vX*vX)+(vY*vY))/(millis()-t[i].update);
        t[i].speed =(t[i].speed * 0.9) + vS * 0.1;
      }
      else {
        t[i].speed = 0;
      }
      //println("ob "+i+" X "+t[i].X+", Y "+t[i].Y+", T ",+(millis()-t[i].update)+" --> "+t[i].speed);
      t[i].lastX = t[i].X;
      t[i].lastY = t[i].Y;
      t[i].update = millis();
    }
    
    // calculate distance to other targets and merge sum of reciprocals of squares into average
    //println("prox for "+i+" crowd "+t[i].crowding);
    double min = 999999;
    int nearest = -1;
    double sums = 0.0;
    for (int j = 0; j < t.length; j++) {
      if (i != j && t[i].isAlive() && t[j].isAlive()) {
        double sqs = Math.pow((t[i].X-t[j].X),2) + Math.pow((t[i].Y-t[j].Y),2);
        if (sqs > 0)
          sums += 2.0 / sqs;
        //println("  i "+i+"  "+t[i].X+" j "+j+" "+t[j].X+" sqs "+sqs+" sums "+sums);
        if (sqs < min) {
          min = sqs;
          nearest = j;
          //println("  min "+min+" nearest "+nearest);
        }
      }
      //println(""+i+" sums "+sums+" crowding "+t[i].crowding);
    }
    // limit and filter crowding metric into store
    t[i].crowding = constrain((t[i].crowding * 0.7) + (float)sums * 0.3, 0, 20);
    //println("final "+i+" sums "+sums+" crowding "+t[i].crowding+" alive "+t[i].alive);
    //println("final  min "+min+" nearest "+nearest);
    // update details of nearest object
    if (nearest >= 0) {
      t[i].nearest = nearest;
      t[i].nearest_distance = (float)Math.sqrt(Math.pow((t[i].X-t[nearest].X),2) + Math.pow((t[i].Y-t[nearest].Y),2));
      t[i].nearest_bearing = (float)Math.atan((t[i].Y-t[nearest].Y)/(t[i].X-t[nearest].X));  
    } else {
      t[i].nearest = -1;
      t[i].nearest_distance = 0;
      t[i].nearest_bearing = 0;
    }
    if (t[i].isAlive()) {
      //println("ob "+i+" X "+t[i].X+", Y "+t[i].Y+" --> "+t[i].nearest);
    }
    
  }   
}
