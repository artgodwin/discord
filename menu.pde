int mouseclickX = -1;
int mouseclickY = -1;

// bitmaps and text constants are all horribly intertwined here, and the literal optiopn bits are used in discrod.pde
long options   = 0x2 | 0x4 | 0x8 | 0x10 | 0x20 | 0x40 | 0x80 | 0x800;

// options which affect interactions (others are view on/off only)
long warnopts = 0x700;
// replay control
long playopts = 0x3800;

boolean testmouse(int X, int Y, int radius)
{
  
 return false; 
}


long testmenu(int mX, int mY, int size, String[] text, long options, color lowcolor, color highcolor, color warncolor, color playcolor) 
{
  int select = -1, selected = -1;
  pushMatrix();

  translate(mX,mY);

  for(int i = 0; i < text.length; ++i) {
    int buttonX2 = mX + int(textWidth(text[i]));
    int buttonY2 = mY + (size*i);
    int buttonY1 = buttonY2 - size;
    if (mouseX > mX && mouseX < buttonX2 && mouseY > buttonY1 && mouseY < buttonY2) 
      select = i;
    else
      select = -1;
    if (mouseclickX > mX && mouseclickX < buttonX2 && mouseclickY > buttonY1 && mouseclickY < buttonY2) {
      selected = i;
      mouseclickX = mouseclickY = -1;
    }
    
    boolean optset = ((options & (1<<i)) > 0);

    if (optset & (warnopts & (1<<i))>0) 
        fill(warncolor);
    else if (optset) 
        fill(highcolor);
    else
        fill(lowcolor);
    
    textAlign(LEFT);
    textSize(size);
    text(text[i],0,i*size);
  }
  popMatrix();
  
  return selected;
}

void mousePressed() 
{
  mouseclickX = mouseX;
  mouseclickY = mouseY;
}

void drawmenu(int tranx, int trany)
{
  String[] menu = { "Grid", "Outline", "View", "Map",
                    "Left sensor", "Right sensor", "Linked sensors", 
                    "MIDI", 
                    "Move", "Hide", "Align", 
                    "", 
                    "Coordinates","Freeze","Clear", "Quit"
                  };

  long menuopt = testmenu(tranx, trany, textsize, menu, options, 
                    textlocolor, texthicolor, textwarncolor, textplaycolor);  

  if (menuopt >= 0) {
    // if a mode button, clear the others
    if (((1<<menuopt) & warnopts & ~options) > 0)  
      options &= ~warnopts;
    // flip a normal option bit
    options ^= (1<<menuopt);
  }

  // set the globals
  grid =    (options & 0x01)   > 0;
  outline = (options & 0x02)   > 0;
  view =    (options & 0x04)   > 0;
  map    =  (options & 0x08)   > 0;

  leftobs = (options & 0x10)   > 0;
  rightobs = (options & 0x20)  > 0;
  linkedobs = (options & 0x40) > 0;
  midion =  (options & 0x80)   > 0;

  move   =  (options & 0x100)  > 0;
  hiding =  (options & 0x200)  > 0;
  align  =  (options & 0x400)  > 0; 
  live   =  (options & 0x800)  > 0;
  
  coords =  (options & 0x1000) > 0;
  freeze =  (options & 0x2000) > 0;
  clear  =  (options & 0x4000) > 0;
  quit   =  (options & 0x8000) > 0;
}   
