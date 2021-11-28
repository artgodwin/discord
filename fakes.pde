  // maintain fake objects 

int NUMFAKES = 10;

class Fake {
  float centreX;
  float centreY;
  float radius;
  float finalradius;
  float speed;
  float angle;
  float size;
  int active;
  long ticks;
  long startup;

  Fake(float X, float Y, long T, float R, float Z, float S) {
    centreX = X;
    centreY = Y;
    radius = maxdist;
    finalradius = R;
    speed = (R > 0) ? S/R : 0;
    size = Z;
    angle = 0;
    ticks = 0;
    startup = T * 1000;
    active = 0;
  }
}

Fake[] fakes;



void startfakes(){

  fakes = new Fake[NUMFAKES];
  int i = 0;
                       //       T    R    Z    S
  fakes[i++] = new Fake(0,0.1,  1, 3.0, 0.4, 0.6);
  fakes[i++] = new Fake(0.1,0,  5, 2.0, 0.3, -0.3);
  fakes[i++] = new Fake(0.2,0, 15, 3.2, 0.3, 0.7);
  fakes[i++] = new Fake(0,0.2, 20, 3.9, 0.4, 0.5);
//  fakes[i++] = new Fake(0.1,0, 25, 1.3, 0.5, 0.5);
//  fakes[i++] = new Fake(0,0.2, 30, 2.2, 0.3, -0.8);
//  fakes[i++] = new Fake(0.2,0, 40, 1.9, 0.4, 0.4);
//  fakes[i++] = new Fake(0,0.1, 50, 3.6, 0.5, 0.6);

  // marker for end of list
  fakes[i++] = new Fake(0,0,0,0,0,0);
}

void updatefakes(Fake[] fakes, Target[] targets, float X, float Y) {

  //println("fakes at "+X+", "+Y+", dscale "+dscale);
  
  for(int i = 0; i < fakes.length; ++i) {

    Fake f = fakes[i];
    
    if (f.finalradius < 0.001)
      break;  // end of list
      
    if (f.startup >= 0 && millis() > f.startup) {
      f.active = 1; // start a fake after delay
      f.startup = -1;
    }

    if (f.active > 0) {
      f.angle += (millis()-f.ticks)*f.speed/1000;

      Target t = targets[i];
      t.X = X/dscale + f.centreX + (f.radius * cos(f.angle));
      t.Y = Y/dscale + f.centreY + (f.radius * sin(f.angle));
      t.cwidth = f.size;
      t.pdepth = f.size;
      t.alive  = true;
      t.zombie = !true;
      t.lastseen = millis();
      t.cdirty = true;   // polar corrdinates need updating
      // bring object slowly into final orbit
      f.radius = ((f.radius * abs(f.speed)) + (f.finalradius * 0.005)) / (abs(f.speed) + 0.005);
      fakes[i].ticks = millis();      
    }
  }
}
