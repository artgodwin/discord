// names

String planet_names[] = { "Sun", "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune" };  

// distances from the sun, normalised to earth
// http://hanskayser.com/EZ/kayser2/kayser2/index.php

float planet_distances[] = { 0.39, 0.72, 1, 1.52, 5.2, 9.54, 19.19, 30.11 };
float norm_distances[] = { 0.2, 0.35, 0.3, 0.4, 1.0, 2.0, 4.0, 6.0 };
float planet_octave[] = { 1.58, 1.44, 1, 1.52, 1.3, 1.2, 1.2, 1.875 };

// 8 evenly distributed bands
float even_distances_8[] = { 1,2,3,4,5,6,7,8,9 };

// 4 evenly distributed bands
float even_distances_4[] = { 1,2,3,4,5 };

// speeds / harmonies according to Kepler
// https://www.kilibro.com/books/0871692090/the-harmony-of-the-world
float planet_speed[] = { 16, 12, 10, 8, 4, 3, 0, 0 };


void draworbit(float x, float y, float rad, color lines) {

  float llist[] = planet_distances;
  
  pushMatrix();
  
  translate(x,y);
  fill(0,0);
  stroke(lines);
  strokeWeight(2);
  float scale = 2 * rad / llist[llist.length-1];

  for(int i = 0; i < llist.length; ++i) {
    println(planet_names[i] + " "+llist[i]+" "+llist[i]*scale);
    arc(0,0,llist[i]*scale,llist[i]*scale,0,2*PI);
  }  

  popMatrix();
}

// may get changed to 4 during init
float ringlist[] = even_distances_8;

void chooserings(int ringcount)
{
  // choose list of rings according to option
  if (ringcount == 8)
    ringlist = even_distances_8;
  else
    ringlist = even_distances_4;
}

void drawrings(float x, float y, float maxdiam, color lines) 
{
  pushMatrix();
  
  translate(x,y);
  fill(0,0);
  stroke(lines);
  strokeWeight(2);
  float scale = maxdiam / ringlist[ringlist.length-1];

  for(int i = 0; i < ringlist.length; ++i) {
    arc(0,0,ringlist[i]*scale,ringlist[i]*scale,0,2*PI);
  }  

  popMatrix();
}

// draw a cursor so its location can be labelled. Migt be neater to do this by turning it into another sort of target

void drawcursor(float x, float y, float maxdiam, color lines) 
{
  pushMatrix();
  
  translate(mouseX,mouseY);
  fill(lines);
  stroke(lines);
  strokeWeight(2);

  // crosshair cursor
  line(-5,0,5,0);
  line(0,-5,0,5);

  float dist = sqrt((mouseX-x)*(mouseX-x)+(mouseY-y)*(mouseY-y));
  float angle = ((mouseX-x) > 0) ? 180 - degrees(asin( (mouseY-y)/dist )) : degrees(asin( (mouseY-y)/dist )); 
 
  textAlign(LEFT);
  text(nf(dist/dscale,2,2),textsize, textsize*0);
  text(nfs(angle,2,2),textsize, textsize*1);
  //text(nf(mouseX-x,2,2),textsize, textsize*2);
  //text(nf(mouseY-y,2,2),textsize, textsize*3);

  popMatrix();
}


// return properties of targets in fixed ranges
// this currently assumes the rings are equally spaced

// the band (max for centre, decreasing until 0 for outside) in which the object sits
int orbit(float dist, float radius)
{
  int orbit = floor((dist/radius)*float(ringlist.length)); 
  //println("d "+t.dist+" radius "+radius+" len "+ringlist.length+" orbit "+orbit);
  return (orbit >= ringlist.length) ? 0 : ringlist.length - orbit;
}

// the offset within the band (99 at inner ring, 0 at outer ring)
int drift(Target t, float radius)
{
  return floor((1.0-((t.dist/radius)*float(ringlist.length)%1.0)) * 100);
}

// the angle in the orbit - 0 at tdc (relative to 90 at top), 359 at almost a full circle
// neg tdc indicates angular rotation should be reversed so cw becomes positive
int phase(Target t, float tdc)
{
  int phase;
  if (tdc < 0)
    phase = int(360 - tdc - t.angle)%360;
  else
    phase = int(360 + tdc + t.angle)%360; 

  //println("angle "+t.angle+" -> "+phase);
  return phase;
}

// the location in cartesian coordinates relative to a reference (nominally the centre of the orbits)
// and scaled to make 1.0 the full width/height

float cartX(Target t, float ref)
{
  return (t.X + ref);
}

float cartY(Target t, float ref)
{
  return (t.Y + ref);  
}

float crowding(Target t)
{
   return t.crowding; 
}
