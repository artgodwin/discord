import oscP5.*;
import netP5.*;
import themidibus.*;
  
// parameters

// size of screen display (0 for fullscreen)
// size parameters need to be literals and either fullScreen() or size() called at start of code
void setup() {

  //fullScreen();
  size(1200,800);

  moresetup();
}


// port for OSC
int oscport = 7000;

// default distance between lidars and angles from a line joining their centres
float separation = 8.2;
float left_lidar_angle = 30;
float right_lidar_angle = 30;

// scalings to fit map onto Processing screen
float maxdist = 10.0;
float dscale =  height/maxdist;  // gets set again after window is sized

// time out targets that have gone too long without refresh
long overaged = 500;

// choice of rings/orbits (only 4 & 8 permitted)
int rings = 4;

// text in menus
int textsize = 16;


// colours

color cgridr    = color(100,80,80);
color cgridl    = color(80,100,80);
color cgridu    = color(80,80,100);
color cborderr  = color(150,100,100);
color cborderl  = color(100,150,100);
color cborderu  = color(100,100,150);
color ctargetr  = color(200, 50, 50);
color ctargetl  = color(50, 200, 50);
color ctargetu  = color(50, 50, 200);
color ctargetf  = color(255);
color cbacking  = color(80);
color cmandela  = color(175);
color caura     = color(100,0,80,130);
color czombie   = color(100);
color cdims     = color(80);
color csensor   = color(10,100,100);
color textlocolor = color(100,100,80);
color texthicolor = color(200,200,160);
color textwarncolor = color(200,100,100);
color textplaycolor = color(100,100,200);
color cmouse    = color(150);
color cmidi     = texthicolor;

// switches

// the option bits in menu.pde quickly override the values in the flags (and should be merged)
// long options   = 0x2 | 0x4 | 0x8 | 0x10 | 0x20 | 0x40 | 0x80 | 0x800;
boolean  grid      = false; // 0x1
boolean  outline   = true, status = true;
boolean  view      = true;
boolean  map       = true;
boolean  leftobs   = true; // 0x10
boolean  rightobs  = true;
boolean  linkedobs = true;
boolean  midion    = true;
boolean  move      = false; // 0x100
boolean  hiding    = false;
boolean  align     = false;
boolean  live      = true;
boolean  play      = false; // 0x1000
boolean  record    = false;
boolean  coords    = false;
boolean  freeze    = false;
boolean  clear     = false;
boolean  quit      = false;

void moresetup() {
  
  frameRate(20);

  startlayout(rings);
  starttargets();
  startosc(oscport);
  startmidi(rings);
  startfakes();
}


void draw() {

  if (separation > 1.0)
    realdraw();
}


void realdraw() {

  background(0);

  // lay out the sensor fields
  dscale =  height/maxdist;
  
  // green, left
  float poslx = (width-dscale*separation)/2;
  float posly = height*(5.0/6);    // 5/6 from top
  float angl = -90 -left_lidar_angle;            // degrees ccw from centreline facing right
  
  // pink, right                                       
  float posrx = poslx + (dscale*separation); 
  float posry = posly;  
  float angr  = 90 +right_lidar_angle;          // degrees cw from centre facing left
 
  // blue, unified                                       
  float posux = (poslx + posrx)/2.0;
  float posuy = (posly + posry)/2.0;  
  float angu  = (angl  + angr)/2.0;   // halfway between sensors, pointing at 90  from their joining line
 
  

  // right side
  if (edger.edge > 0) {
    if (grid) 
      drawgrid(posrx, posry, angr, cgridr);
    drawedge(edger, posrx, posry, angr, cborderr);
    //drawsensor(posrx, posry, angr, separation, 180-angr /*90-right_lidar_angle*/, csensor);
  }
  
  // left side
  if (edgel.edge > 0) {
    if (grid) 
      drawgrid(poslx, posly, angl, cgridl);
    drawedge(edgel, poslx, posly, angl,cborderl);
    //drawsensor(poslx, posly, angl, separation,-angl/*90+left_lidar_angle*/, csensor);
  }
  
  // combined coverage
  if (edgeu.edge > 0 && edgeu.edge == edgeu.back) {
    if (grid) drawgrid(posux, posuy, angu, cgridu);
    drawedge(edgeu, posux, posuy, angu,cborderu);
  }

  int rmargin = width - (textsize * 12);
  int lmargin = textsize * 3;
  
  // status messages from sources
  if (linkedobs)
    drawstatus(edgeu.text, rmargin, height - (textsize * 4), textsize, cborderu);
  if (rightobs)
    drawstatus(edger.text, rmargin, height - (textsize * 5), textsize, cborderr);
  if (leftobs)
    drawstatus(edgel.text, rmargin, height - (textsize * 6), textsize, cborderl);


  // report dimensions and angles
  if (leftobs && rightobs)
     drawstatus("spacing "+nf(separation,1,2), lmargin, height - (textsize * 4), textsize, cdims);
  if (rightobs)
     drawstatus("right "+nf(right_lidar_angle,1,2), lmargin, height - (textsize * 5), textsize, cborderr);
  if (leftobs)
     drawstatus("left "+nf(left_lidar_angle,1,2), lmargin, height - (textsize * 6), textsize, cborderl);
  
  // draw the sound overlay
  //if (map) drawcube((posrx+poslx)/2,height/2,width/4,cmandela);
  //if (map) drawhept((posrx+poslx)/2,height/2,width/4,cmandela);
  //if (map) draworbit((posrx+poslx)/2,height/2,width/4,cmandela);
  
  if (map) drawrings((posrx+poslx)/2,height/2,separation*dscale,cmandela);
  
  if (rightobs) drawtargetsP(targetsr, posrx, posry, angr, ctargetr, false, 'r');
  if (leftobs)  drawtargetsP(targetsl, poslx, posly, angl, ctargetl, false, 'l');

  // generate fake trails
  //updatefakes(fakes, targetsu, 0.0, posuy-height/2);

  // update polar coords (and other derived values), including offset between sensor centreline and map centre
  updatederived(targetsu, 0.0, (height/2)-posuy,0.0);
  
  //println(millis() + " draw targets");
  if (linkedobs) { 
 
    // cartesian plot of unified data
    // drawtargetsC(targetsu, (posrx+poslx)/2, posuy, ctargetu, true, 'u');

    // polar plot of unified data - should be identical
    drawtargetsP(targetsu, (posrx+poslx)/2, height/2, 0, ctargetu, true, 'u');
  }

  // draw cursor if required
  if (coords && (mouseX > lmargin + (6*textsize)) && (mouseX < rmargin - (1*textsize)))
    drawcursor((posrx+poslx)/2,height/2,separation*dscale,cmouse);
  
  // send midi output : note this needs unified data's polar form to have been made valid by updatederived()
  // println(millis() + " midi");
  if (midion) miditargets(targetsu, separation/2.0, ((height/2)-posuy)/dscale);

  // provide controls to toggle and set some features
  //println(millis() + " menu");
  drawmenu(width - (textsize * 10), textsize * 4);
  
  // clear, quit, calibrate, record etc.
  //println(millis() + " user actions");
  useractions();
}
