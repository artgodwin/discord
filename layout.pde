// grid lines at 1m
float GRIDCIRCLES = 1.0;
int   EDGEPOINTS = 500;

class Layout {

  float inc = 0.5;
  int edge = 0;
  int back = 0;
  int alim = 0;
  float border[];
  float backing[];
  String text;
  
  Layout(String initialtext) {
    inc = 0.5;
    edge = 0;
    back = 0;
    alim = 0;
    border = new float[EDGEPOINTS];
    backing = new float[EDGEPOINTS];
    text = initialtext;
  }
}

Layout edgel;  // coordinates for objects from left sensor
Layout edger;  // coordinates for objects from right sensor
Layout edgeu;  // coordinates for objects in the combined view

void startlayout(int rings) {
  
  edgel = new Layout("-left-");
  edger = new Layout("-right-");
  edgeu = new Layout("--");

  chooserings(rings);
}

void clearlayout()
{
  edgel.edge = edgel.back = edgel.alim = 0;
  edger.edge = edger.back = edger.alim = 0;
  edgeu.edge = edgeu.back = edgeu.alim = 0;
}


void drawborder(float outline[], float inc, int count) {

  float x = 0, lastx = 0, y = 0, lasty = 0, a, d;

  //println("drawborder from "+outline[0]+" for "+count+" at "+inc);

  for (int i = 0; i < count; ++i) {
    d = outline[i] * dscale;
    a = (140.0-(i*inc)) * TWO_PI / 360.0;
    //println(" edge "+i+" at "+a+", "+d);
    x = d * cos(a);
    y = d * sin(a);
    //println(" edge "+i+" at "+x+", "+y);
    //println(" edge line "+lastx+","+lasty+" to "+x+", "+y);
    line(lastx,lasty,x,y);
    lastx = x;
    lasty = y;
  }
  line(x,y,0,0);  // close the shape
}

// draw a measurement grid over the sensor quadrant

void drawgrid(float tranx, float trany, float trangle, int cgrid)
{
  pushMatrix();

  noFill();
  stroke(cgrid);

  translate(tranx,trany);
  rotate(radians(trangle));
 
  float radius;
  for (radius = GRIDCIRCLES; radius < maxdist + 1; radius += GRIDCIRCLES) 
    arc(0,0,radius*2*dscale,radius*2*dscale,radians(40),radians(140));

  radius -= GRIDCIRCLES;
  for (float angle = radians(40); angle <= radians(141); angle += radians(20))
    line(0,0,radius*dscale*cos(angle),radius*dscale*sin(angle));

  popMatrix();
}

// draw the measured or restricted edge of the sensor's view

void drawedge(Layout edge, float tranx, float trany, float trangle, int cborder)
{
    // creep boundary to smooth out painting - a few pixesl per draw()
    if (edge.edge > edge.alim) {
      edge.alim = min(min(edge.edge,edge.back),edge.alim+10);
    }
    
    pushMatrix();
    
    translate(tranx,trany);
    rotate(radians(trangle));
    
    strokeWeight(2);
    stroke(cborder);
    if (outline) drawborder(edge.border,edge.inc,min(edge.alim,edge.edge));

    strokeWeight(1);
    stroke(cbacking);
    if (view) drawborder(edge.backing,edge.inc,min(edge.alim,edge.back));

    popMatrix(); 
}

// plot the lidars in each other's view

void drawsensor(float tranx, float trany, float trangle, float separation, float sangle, int csensor)
{
    pushMatrix();

    translate(tranx,trany);
    rotate(radians(trangle));

    float sensorsize = 0.3 * dscale;
    sangle = radians(sangle);
    separation *= dscale;
    fill(0);
    stroke(csensor);
    strokeWeight(3);
    ellipse(separation*cos(sangle),separation*sin(sangle),sensorsize,sensorsize);

    popMatrix();
}

// refresh sensor's status text

void drawstatus(String text, float tranx, float trany, float size, int ctext)
{
  //println(millis()," status "+source.text);
  
  pushMatrix();
  fill(0);
  textAlign(LEFT);
  textSize(size);
  fill(ctext);
  text(text,tranx,trany);

  popMatrix();
}
