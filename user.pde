
long quitting;
long clearing;

void useractions()
{
  // control record/play (force live if neither play nor record) .. could do just play/record/neither ?
  if ((options & 0x3000) == 0) 
     options |= 0x800;

  // empty screen
  if (clear) {
    if (clearing == 0) 
      clearing = millis();
    if ((millis() - clearing) > 500) {
      cleartargets();
      clearlayout();
      options &= ~0x4000;
      clear = !true;
    }
  }
  else
    clearing = 0;
    

  // cleanup on exit
  if (quit) {
    if (quitting == 0) 
      quitting = millis();
    if ((millis() - quitting) > 500)
      exit();
  }
  else
    quitting = 0;
}