
void drawhept(float x, float y, float side, color lines) {

  float sideangle = 2*PI/7;
  float shortangle= 4*PI/7;
  float longangle=  6*PI/7;
  float radius = side/(2.0*sin(sideangle/2));
  float longside = 2.0 * (radius * 1.1) * sin(sideangle);
  float shortchord=2*side*(sin((PI-sideangle)/2));
  float longchord=side*(1 + 2*sin((PI/2)-sideangle));

  pushMatrix();

  translate(x,y);
  stroke(lines);  
  fill(0,0);  // transparent panes

  translate(0,-radius);

  pushMatrix();
  rotate(sideangle/2);
  for (int i = 0; i < 7; ++i) {
    line(0,0,side,0);
    translate(side,0);
    rotate(sideangle);
  }

  popMatrix();
  pushMatrix();
  rotate(longangle/2);
  
  for (int i = 0; i < 7; ++i) {
    line(0,0,longchord,0);
    translate(longchord,0);
    rotate(longangle);
  }

  popMatrix();
  pushMatrix();
  rotate(shortangle/2);
  
  for (int i = 0; i < 7; ++i) {
    line(0,0,shortchord,0);
    translate(shortchord,0);
    rotate(shortangle);
  }

  popMatrix();
  popMatrix();
}


void drawcube(float x, float y, float side, color lines)
{  
  pushMatrix();

  translate(x,y);
  stroke(lines); 
  fill(0,0);  // transparent panes

  // move from centre to start point
  translate(side/-2,side*(sqrt(2.0)+1.0)/-2);

  // draw 8 boxes with 45 degree rotation
  for (int i = 0; i < 8; ++i) {
    rect(0,0,side,side);
    translate(side,0);
    rotate(PI/4.0);
  }

  popMatrix();
}