MidiBus midi;

// the possible midi interfaces used to stream data to the synthesizer
String midinames[] = {
    "CH345 [hw:1,0,0]",     // unbranded midi pod
    "UA25 [hw:1,0,0]",      // Edirol UA25
    "USB [hw:1,0,0]",       // Scarlett 8i6
    "VirMIDI [hw:1,0,0]",   // local virtual midi
    "Real Time Sequencer"   // built-in
};

int port = -1;              // selection from above list


class MidiTarget {
  int  pitch;
  int  velocity;
  int  control1;
  int  control2;
  int  control7;
  int  control8;
  int  control10;
  int  off;
  int repeats;
  long timer;
  
  MidiTarget() {
    pitch = 0;
    control1 = -1;
    control2 = -1;
    off = 1;
    repeats = 0;
    timer = 0;
  }
};

// index 0 is 'outside', rising towards centre
int notes4[] = { 0, 60, 67, 71, 74, 79 };
int notes8[] = { 0, 60, 67, 71, 74, 79, 86, 90, 93, 98 };
int notes[] = notes8;

// voices - because of midi channel numbering, voice 0 is understood as channel 1
int voices[] = { 0, 1, 2, 3, 4, 5, 6, 7 };

// record which notes have been sent to remove duplicates and allow correct note-off
MidiTarget MidiTargets[];


void startmidi(int rings) {

  MidiBus.list(); 
  String outs[] = MidiBus.availableOutputs();
  for( int j, i = 0; i < outs.length; ++i) {
    for(j = 0; j < midinames.length; ++j) {
      //println("test \""+outs[i]+"\" against \""+midinames[j]+"\"");
      if (midinames[j].equals(outs[i])) {
        //println("match");
        port = j;
        break;
      }
    }
    if (port >= 0)
      break;
  }
  if (port >= 0) {
    println("opening midi device "+midinames[port]);
    midi = new MidiBus(this, -1, midinames[port]);  
  }
  else
    println("cannot find midi device");
  
  MidiTargets = new MidiTarget[NUMTARGETS];
  for(int i = 0; i < MidiTargets.length; ++i)
    MidiTargets[i] = new MidiTarget();

  //select notes set to match ring count
  if (rings == 4)
    notes=notes4;
    
  // set up rings markers - probably done by startlayout but important for midi too so do it again
  chooserings(rings);
}


long ZERO_TIME   = 3000;
int  MAX_REPEATS = 5;

// send midi only on change, or after a timeout when off

int activechannels = 0;

void midiout(int channel, int pitch, int velocity, int control1, int control7, int control10, int control8) {
    
  if (channel >= voices.length)
    return;
  
  int voice = voices[channel];
    
  // paint values in corner
  if (port >= 0)
    drawstatus("interface   "+midinames[port],textsize*3, (textsize * 4), textsize, cmidi);

  if (pitch != 0) {
    textAlign(RIGHT);
    drawstatus("ch"+(voice+1)+"  note "+notes[pitch]+",  X         , Y         , prx        , spd",
                              textsize*3, (textsize * (5+channel)), textsize, cmidi);
    drawstatus(" "+control10,textsize*11, (textsize * (5+channel)), textsize, cmidi);
    drawstatus(" "+control7, textsize*15, (textsize * (5+channel)), textsize, cmidi);
    drawstatus(" "+control1, textsize*20, (textsize * (5+channel)), textsize, cmidi);
    drawstatus(" "+control8, textsize*25, (textsize * (5+channel)), textsize, cmidi);
  }
  
  // send noteOn if pitch is new
  if (pitch > 0 && pitch != MidiTargets[channel].pitch) {
    if (velocity > 0 && pitch > 0) {
      println(millis()+" midi send voice "+voice+" pitch "+notes[pitch]+" vel "+velocity);
      midi.sendNoteOn(voice, notes[pitch], velocity); // Send a Midi noteOn
    }
  }
  
  // send noteOff if pitch has changed
  if ((pitch == 0)  || (pitch != MidiTargets[channel].pitch)) {
    
      println(millis()+" midi off voice "+voice+" pitch ix "+MidiTargets[channel].pitch);
      midi.sendNoteOff(voice, notes[MidiTargets[channel].pitch], 0); // Send a Midi noteOff for the previous note
      MidiTargets[channel].timer = millis() + ZERO_TIME;      // schedule another noteoff
      MidiTargets[channel].repeats = 0;
      MidiTargets[channel].off = MidiTargets[channel].pitch;  // remember for next repeat
  }
  
  // send noteOff if a retransmission is needed  
  if (pitch == 0 && MidiTargets[channel].timer != 0 && (MidiTargets[channel].timer < millis())) {

    println(millis()+" repeat midi off voice "+voice+" pitch ix "+MidiTargets[channel].off);
    
    midi.sendNoteOff(voice, notes[MidiTargets[channel].off], 0); // Send a Midi noteOff for the previous note

    if (MidiTargets[channel].repeats++ > MAX_REPEATS * notes.length)
      MidiTargets[channel].timer = 0;      // don't schedule another noteoff
    else
      MidiTargets[channel].timer = millis() + ZERO_TIME;      // schedule another noteoff

    // rotate the note-off pitch so all get sent in rotation 
    if (++MidiTargets[channel].off >= notes.length)
      MidiTargets[channel].off = 1;
  }
  
  // record for future use
  MidiTargets[channel].pitch = pitch;
  MidiTargets[channel].velocity = velocity;
  
  
  if (pitch != 0 && (control1 != MidiTargets[channel].control1)) {   // crowding
    //println(voice+" cc1 "+control1);
    midi.sendControllerChange(voice, 1, control1); // Send a CC1 with the Y coordinate
    MidiTargets[channel].control1 = control1;
  }
  
  if (pitch != 0 && (control7 != MidiTargets[channel].control7)) {   // Y
    //println(voice+" cc7 "+control7);
    midi.sendControllerChange(voice, 7, control7); // Send a CC7 with the crowding metric
    MidiTargets[channel].control7 = control7;
  }    

  if (pitch != 0 && (control10 != MidiTargets[channel].control10)) {   // X
    //println(voice+" cc10 "+control10);
    midi.sendControllerChange(voice, 10, control10); // Send a CC10 with the X coordinate
    MidiTargets[channel].control10 = control10;
  }    
/*
  if (pitch != 0 && (control8 != MidiTargets[channel].control8)) {   // speed
    //println(voice+" cc8 "+control8);
    midi.sendControllerChange(voice, 8, control8); // Send a CC8 with the speed
    MidiTargets[channel].control8 = control8;
  }
*/
}

// convert parameters to midi values (0..127) as a fraction of the radius of the field

void miditargets( Target[] targets, float range, float yoffset) {

  for (int i = 0; i < targets.length  && i < voices.length; ++i) {
    if (targets[i].zombie) {
      // target disappearing - send note off
        println("target "+i+" is a zombie - note off");
        midiout(i,0,0,0,0,0,0);    
    }  
    else if (targets[i].isAlive()) {

      //println("-->i "+i+" x "+cartX(targets[i],0)+" y "+cartY(targets[i],0));
      // orbit 0 is made to be outside and highest at the centre
      int orbit = orbit(targets[i].dist,range);
      //int phase = phase(targets[i],-270);
      //int drift = drift(targets[i],range);
      int X = int(constrain(map(cartX(targets[i], 0),-range,range,4,124),4,124));
      int Y = int(constrain(map(cartY(targets[i], yoffset),-range,range,60,110),60,110));
      int density = int(constrain(map(crowding(targets[i]),0,10,0,127),0,127));
      int velocity = 127; 
      int speed = int(constrain(map(targets[i].speed,0,2,0,127),0,127));

      //if (!freeze)
        //println("midi ch "+i+" X "+cartX(targets[i],0)+"-> "+X+", Y "+cartY(targets[i],yoffset)+"-> "+Y+", density "+crowding(targets[i])+"-> "+density+", speed "+speed);
      
      // catch unexpected FP errors
      if (Float.isNaN(cartX(targets[i],0)) || Float.isNaN(cartY(targets[i],0)))  {
        println("midi ch "+i+" X "+cartX(targets[i],0)+"-> "+X+", Y "+cartY(targets[i],yoffset)+"-> "+Y+", density "+crowding(targets[i])+"-> "+density+", speed "+speed); //<>//
        println("  ********** stop *************");
        exit();
      }
      
      if ((orbit >= 0) && (orbit < notes.length))  {
        midiout(i,orbit,velocity,/*(phase*127)/359,(drift*127)/99,*/density,Y,X,speed);
      }
    } else {
      // send note-off for lost target
      //println("ob "+i+" neither active nor zombie");
      //midiout(i,0,0,0,0,0,0);
    }
  }

  // print cursor midi values
  if  (coords) {
    float x = (float)(mouseX-width/2)/(float)dscale;
    float y = (float)(mouseY-height/2)/(float)dscale;
    float dist = sqrt((x*x)+(y*y));
    int X = int(constrain(map(x,-range,range,4,124),4,124));
    int Y = int(constrain(map(y,range,-range,60,110),60,110));
    int orbit = orbit(dist,range);
    drawstatus("crsr  note "+nf(notes[orbit],2)+",  X         , Y",textsize*3, (textsize * 9), textsize, cmidi);
    drawstatus(" "+X, textsize*11, (textsize * 9), textsize, cmidi);
    drawstatus(" "+Y, textsize*15, (textsize * 9), textsize, cmidi);
  }
}
