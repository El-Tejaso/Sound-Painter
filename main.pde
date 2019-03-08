//This scetch is made for ms paint 'artists' like me to create sound effects from basically nothing
//I originally made it for myself, since I didn't want to buy a subscription for any of those 'Pro Tools'
//Use WASD to move the waveform left and right and zoom in and out,
//use the mouse left click and right click to use the various tools and TAB to switch tools 
//use  Z X C V F B to change the tool parameters. hold the keys down while moving the mouse, then release them. pressing shift often
//allows for smaller adjustments/slower use

final int INT_MAX = 2147483647;

final String openAFilepath = "";//Set this to blank for a new waveform, or enter in a filepath for it to open something (prefferably a sound) (Not yet implemented)
//these settings only work if we aren't opening something
final int FPS = 44100;//the samples in the audio file per second.
final float duration = 1;//this is the length of the sample. currently can't be changed after creation

final float MAXFREQUENCY = FPS;
final float MINFREQUENCY = 10;

//These are UI colors, feel free to change/better them
color backgroundColor;
color waveformColor;
color axesColor;
color playCursorColor;
color sampleInfoColor; 
color toolColor;
color commandColor;
color disabledToolColor;
color buttonFill;
color buttonPressFill;
color activeCursorColor;
color cursorColor;

//These are all UI related, no need to mess with them
final int MAXBARS = 500;
final int ZOOMAMOUNT = 500;
final int MINWINDOWSIZE = 100;
final int RESOLUTION = 1000;
final int DISPLAYPRECISION = 4;

//From here on out is sparsely commented territory, edit the code at your own peril 
import processing.sound.*;
import java.io.BufferedOutputStream;
import java.io.FileOutputStream;

AudioSample sample;

void setup() {
  size(800, 600);
  background(255);
  textFont(createFont("Consolas",12));
  
  //yep this is the processing audio sample code
  // Create an array and manually write a single sine wave oscillation into it.
  float[] sinewave = new float[round(FPS*duration)];
  for (int i = 0; i < sinewave.length; i++) {
    sinewave[i] = random(-1,1);
  }
  sample = new AudioSample(this, sinewave, FPS);
  
  //setup the input, did it like this to make adding new keys faster
  keyMappings.put('a', AKey);
  keyMappings.put('A', AKey);
  keyMappings.put('s', SKey);
  keyMappings.put('S', SKey);
  keyMappings.put('d', DKey);
  keyMappings.put('D', DKey);
  keyMappings.put('w', WKey);
  keyMappings.put('W', WKey);
  keyMappings.put('q', QKey);
  keyMappings.put('Q', QKey);
  keyMappings.put('e', EKey);
  keyMappings.put('E', EKey);
  keyMappings.put('c', CKey);
  keyMappings.put('C', CKey);
  keyMappings.put('p', PKey);
  keyMappings.put('P', PKey);
  keyMappings.put('r', RKey);
  keyMappings.put('R', RKey);
  keyMappings.put('b', BKey);
  keyMappings.put('B', BKey);
  keyMappings.put('z', ZKey);
  keyMappings.put('Z', ZKey);
  keyMappings.put('x', XKey);
  keyMappings.put('X', XKey);
  keyMappings.put('v', VKey);
  keyMappings.put('V', VKey);
  keyMappings.put('f', FKey);
  keyMappings.put('F', FKey);
  keyMappings.put('n', NKey);
  keyMappings.put('N', NKey);
  keyMappings.put('/', FSlashKey);
  keyMappings.put('?', FSlashKey);
  keyMappings.put('t', TKey);
  keyMappings.put('T', TKey);
  keyMappings.put(' ', SpaceKey);
  
  /* Default theme
  backgroundColor = color(0,0,0);
  waveformColor = color(125);
  axesColor = color(255,0,0);
  playCursorColor = color(255,255,0);
  sampleInfoColor = color(0,0,255);
  toolColor = color(0,255,0);
  commandColor = color(0,255,255);
  disabledToolColor = color(0,255,0,125);
  buttonFill = color(255,0,0);
  buttonPressFill = color(0,255,0);
  activeCursorColor = color(255);
  cursorColor = color(200);
  //*/
  
  //* ms paint theme
  backgroundColor = color(198,208,224);
  waveformColor = color(248,110,50);
  axesColor = color(0);
  playCursorColor = color(201,224,247);
  sampleInfoColor = color(90);
  toolColor = color(26,106,171);
  commandColor = color(20);
  disabledToolColor = color(26,106,171,125);
  buttonFill = color(213,230,247);
  buttonPressFill = color(201,224,247);
  activeCursorColor = color(0);
  cursorColor = color(125);
  //*/
  
  //set the viewport size
  windowSize = sample.frames();
  cursorA = 0;
  cursorB = sample.frames();
}

int maxWindowSize(){
  return sample.frames()+2000;
}

//Have some helper functions here
boolean pointInside(float mX, float mY,float x, float y, float w, float h){
  if(mX>x){
    if(mX < x+w){
      if(mY > y){
        if(mY < y + h){
          return true;
        }
      }
    }
  }
  
  return false;
}

boolean mouseInside(float x, float y, float w, float h){
  return pointInside(mouseX, mouseY, x, y,w,h);
}

String musicalNote(float hertz){
  //data used to derive algorithm was from http://pages.mtu.edu/~suits/notefreqs.html
  float noteApprox = 17.312*log(hertz)-48.398821;
  if(noteApprox < 0)
    return "";
  String[] musicNotesMain = {
    "C",
    "C#/Db",
    "D",
    "D#/Eb",
    "E",
    "F",
    "F#/Gb",
    "G",
    "G#/Ab",
    "A",
    "A#/Bb",
    "B",
  };
  
  int noteNumber = floor(noteApprox/musicNotesMain.length);
  if((noteNumber>8)||(noteNumber<0)){
    return "Not A Note";
  } 
  
  return musicNotesMain[round(noteApprox) % musicNotesMain.length] + noteNumber;
}

void writeIntAsBytes(OutputStream fstream, int n, int bytes, boolean littleEndian){
  byte[] buffer = {(byte)((n)&0xff),
                   (byte)((n>>8)&0xff),
                   (byte)((n>>16)&0xff),
                   (byte)((n>>24)&0xff)
                   };
  try{
    for(int i = 0; i < bytes;i++){
      if(littleEndian){
        fstream.write(buffer[i]);
      } else {
        fstream.write(buffer[3-i]);
      }
    }
  } catch(Exception e) {
    print(e.getMessage());
  }
}

//mfw this shit actually works :000
void exportFileWav(String fileName){
  //format specs from http://soundfile.sapp.org/doc/WaveFormat/
  OutputStream fstream;
  fstream = createOutput(fileName);
   
  //ChunkID ("RIFF")
  writeIntAsBytes(fstream,0x52494646,4,false);
  
  //ChunkSize: 4 + (8 + (16 for PCM)) + (8 + (NumSamples * NumChannels * BitsPerSample/8))
  writeIntAsBytes(fstream,4 + (8 + (16)) + (8 + (sample.frames() * 1 * 4)),4, true);

  //Format ("Wave")
  writeIntAsBytes(fstream,0x57415645,4,false);
  
  //Subchunk1ID ("fmt ")
  writeIntAsBytes(fstream,0x666d7420,4,false);
  //Subchunk1Size (16)
  writeIntAsBytes(fstream,16,4,true);
  
  //AudioFormat (PCM = 1 == 0x10 in little endian)
  writeIntAsBytes(fstream,1,2,true);
  
  //NumChannels (Mono)
  writeIntAsBytes(fstream,1,2,true);
  
  //Sample rate
  writeIntAsBytes(fstream,FPS,4,true);
  //ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  writeIntAsBytes(fstream,FPS*1*4,4,true);
  //BlockAlign (NumChannels * BitsPerSample/8)
  writeIntAsBytes(fstream,1*4,2,true);
  
  //BitsPerSample
  writeIntAsBytes(fstream,32,2,true);
  
  //Subchunk2ID("data")
  writeIntAsBytes(fstream,0x64617461,4,false);
  
  //Subchunk2Size(NumSamples * NumChannels * BitsPerSample/8)
  writeIntAsBytes(fstream,sample.frames()*1*4,4,true);
  
  //Write the actual data
  for(int x = 0; x < sample.frames();x++){
    writeIntAsBytes(fstream,round(sample.read(x)*INT_MAX),4,true);
  }
  
  try{
    fstream.close();
  } catch(Exception e){
    println(e.getMessage());
  }
}

//INPUT SYSTEM
//not used by the input system, but by us to do stuff only once
boolean[] keyJustPressed = new boolean[21];
boolean[] keyStates = new boolean[21];
boolean keyDown(int Key) { return keyStates[Key]; }
final int AKey = 0;
final int DKey = 1;
final int WKey = 2;
final int SKey = 3;
final int CKey = 4;
final int QKey = 5;
final int EKey = 6;
final int ShiftKey = 7;
final int CtrlKey = 8;
final int PKey = 9;
final int RKey = 10;
final int BKey = 11;
final int ZKey = 12;
final int XKey = 13;
final int VKey = 14;
final int SpaceKey = 15;
final int FKey = 16;
final int NKey = 17;
final int TabKey = 18;
final int FSlashKey = 19;
final int TKey = 20;

boolean shiftChanged = false;
//maps the processing keys to integers in our key state array, so we can add new keys as we please
HashMap<Character, Integer> keyMappings = new HashMap<Character, Integer>();

void keyPressed(){
  if(keyMappings.containsKey(key)){
    keyStates[keyMappings.get(key)]=true;
  }
  
  if(keyCode==SHIFT){
    if(!keyStates[ShiftKey]){
      keyStates[ShiftKey] = true;
      shiftChanged = true;
    }
  }
  
  if(keyCode==CONTROL){
    keyStates[CtrlKey] = true;
  }
  
  if(keyCode==TAB){
    keyStates[TabKey] = true;
  }
}

void keyReleased(){
  if(keyMappings.containsKey(key)){    
    keyStates[keyMappings.get(key)]=false;
    keyJustPressed[keyMappings.get(key)]=false;
  }
  
  if(keyCode==SHIFT){
    if(keyStates[ShiftKey]){
      keyStates[ShiftKey]=false;
      shiftChanged = true;
    }
    keyJustPressed[ShiftKey]=false;
  }
  
  if(keyCode==CONTROL){
    keyStates[CtrlKey]=false;
    keyJustPressed[CtrlKey]=false;
  }
  
  if(keyCode==TAB){
    keyStates[TabKey] = false;
    keyJustPressed[TabKey]=false;
  }
  
  dragStartPos = -1;
  dragDelta = 0;
}

int position = 0; //sample we're looking at
int windowSize = 500;//samples to include in the peripheral

void setView(int amount){
  position = constrain(amount,0,sample.frames()-1);
}

//returns a position on the waveform to a screen point
float toScreenX(int pos){
  return (width/2) + (pos-position)/(float)windowSize * width;
}

int toWaveformX(float screenPos){
  return round((screenPos / width)*windowSize)+position-ceil(windowSize/2);
}

float toWaveformY(float screenPos){
  return -(screenPos - height/2f)/(height/4f);
}

float toScreenY(float frame){
  return -(frame/4.0)*height + height/2;
}

float initCommandY = 20;
float commandY = 20;
float commandSize = 20;
//drawing stuff
void drawCommand(String command){
  textSize(commandSize);
  textAlign(CENTER);
  text(command,width/5, 20 + commandY);
  textSize(12);
  commandY+=20;
  commandSize -=2;
}

void drawWaveform(){
  //Draw waveform
  int spacing = max((windowSize)/RESOLUTION,1);
  int start = position-ceil(windowSize/2.0)-1;
  int end = position+ceil(windowSize/2.0);
  //float gap = spacing * width/(float)(windowSize);
  
  float prev = height/2;
  for(int i = start, counter = 0; i < end; i+=spacing, counter++){
    if(i < 0)
      continue;
      
    if(i >= sample.frames())
      break;
      
    float x1 = toScreenX(i);
    float y2 = toScreenY(sample.read(i));
    //draw individual samples when close enough
    if(windowSize < RESOLUTION){
      line(x1,height/2,x1, y2);
    }
    
    if(counter>0)
      line(toScreenX(i-1),prev,x1,y2);
    
    prev = y2;
  }
}

//draw mimmax time and frames text, as well as ruler lines based on zoom
void drawRuler(){
  textAlign(LEFT);
  int tMin = position - ceil(windowSize/2);
  int tMax = position + ceil(windowSize/2);
  text(nf(tMin/(float)FPS,0,DISPLAYPRECISION) + "s", 0,10);
  text(tMin + "F", 0,20);
  textAlign(RIGHT);
  text(nf(tMax/(float)FPS,0,DISPLAYPRECISION) + "s", width,10);
  text(tMax + "F", width,20);
}

void drawAxes(){
  line(toScreenX(0),height/2,toScreenX(sample.frames()),height/2);
  line(width/2,50,width/2,height/2+50);
  
  line(toScreenX(0),height/4,toScreenX(0),height-height/4);
  line(toScreenX(sample.frames()),height/4,toScreenX(sample.frames()),height-height/4);
  
  textAlign(CENTER);
  text(nf(position/(float)FPS,0,DISPLAYPRECISION) + "s",width/2 + 2,10);
  text(position + "F", width/2 + 2, 22);
  text("domain width: "+windowSize+"F("+ nf((windowSize/(float)FPS),0,DISPLAYPRECISION)+" seconds)", width/2 + 2, 34);
  text("A-B selection width: "+(cursorB-cursorA)+"F("+ nf(((cursorB-cursorA)/(float)FPS),0,DISPLAYPRECISION)+" seconds)", width/2 + 2, 46);
}

int sign(float f){
  if(f>0)
    return 1;
    
  return -1;
}

void drawSampleInfo(){
  int currentSample = toWaveformX(mouseX);
  if((currentSample<0)||(currentSample>=sample.frames()))
    return;
  if(windowSize < RESOLUTION*3){
    float tempX = toScreenX(currentSample);
    strokeWeight(2);
    line(tempX,height/2, tempX, height/2 - (height/4)*sample.read(currentSample));
    strokeWeight(1);
    textAlign(CENTER);
    text(sample.read(currentSample), tempX, height/2 - (height/4)*sample.read(currentSample));
  }
}

//used for dragging the viewport
float dragDelta;
int dragStartPos = -1;

//used for key input drags
float xDragStart = -1;
float yDragStart = -1;
float xDragInit = 0;
float yDragInit = 0;
//used for saving the file
String lastFilename;

//this is the real program
void handleKeyInput(color col){
  commandY = initCommandY;
  commandSize = 20;
  stroke(col);
  fill(col);
  
  //Moveing and zooming will take full priority
  if(keyDown(AKey)||keyDown(DKey)||keyDown(WKey)||keyDown(SKey)){
    //Move the wave left or right
    if(keyDown(AKey)||keyDown(DKey)){
      if(dragStartPos < 0){
        dragStartPos = position;
      } 
      drawCommand("Move position");
      float dragdeltadelta = 0;
      if(keyDown(DKey)){
        drawCommand("-->"); 
        dragdeltadelta = 10;
      } else {
        drawCommand("<--");
        dragdeltadelta = -10;
      }
      
      if(keyDown(ShiftKey)){
          drawCommand("slowly");
          dragdeltadelta /= 12f;
      } 
        
      dragDelta += dragdeltadelta;
      int actualDragAmount = round(sign(dragDelta)*abs((windowSize) * (dragDelta / width)));    
      setView(dragStartPos + actualDragAmount); 
    }
  
    //zoom in or out
    if(keyDown(SKey)||keyDown(WKey)){
      int actualZoomAmount = 0;
      drawCommand("Zoom");
      if(keyDown(SKey)){
        drawCommand("out");
        actualZoomAmount = windowSize/10;
      } else {
        drawCommand("in");
        actualZoomAmount = -windowSize/10;
      }
      
      if(keyDown(ShiftKey)){
        drawCommand("slowly");
        actualZoomAmount /= 3;
      } 
      windowSize = constrain(windowSize + actualZoomAmount, MINWINDOWSIZE, maxWindowSize());
    }
    return;
  }
  
  //change brush width and height based on the delta
  if(keyDown(ZKey)){
    drawCommand("Resize brush");
    if(!keyJustPressed[ZKey]){
      keyJustPressed[ZKey]=true;
      shiftChanged = true;
    }
    
    if(shiftChanged){
      shiftChanged = false;
      xDragStart = mouseX;
      yDragStart = mouseY;
      xDragInit = brushWidth;
      yDragInit = brushHeight;
    }
    
    float dX = mouseX - xDragStart;
    float dY = mouseY - yDragStart;
    if(keyDown(ShiftKey)){
      drawCommand("slowly");
      dX/=4;
      dY/=4;
    }
    
    drawCommand("width: " + brushWidth + " height: " + brushHeight());
    brushWidth = constrain(xDragInit+dX,1,width/2);
    brushHeight = constrain(yDragInit+dY,-height/4,height/4);
    
    line(xDragStart,yDragStart,mouseX,yDragStart);
    line(xDragStart,yDragStart,xDragStart,mouseY);
    drawWidth(brushWidth,brushHeight);
    return;
  }
  
  //change the brush shear based on delta
  if(keyDown(XKey)){
    drawCommand("Set Shear");
    if(!keyJustPressed[XKey]){
      keyJustPressed[XKey]=true;
      xDragStart = mouseX;
      yDragStart = mouseY;
    }
    float dX = mouseX - xDragStart;
    float dY = mouseY - yDragStart;
    float gradient = constrain(dY/dX,-20,20);
    drawCommand("gradient (dY/dX) : " + gradient);
    if(!Float.isNaN(gradient)){
      brushShear = gradient;
    }
    
    line(xDragStart,yDragStart,mouseX,yDragStart);
    line(xDragStart,yDragStart,xDragStart,mouseY);
    drawShear(brushShear);
    return;
  }
  
  //change the brush influence
  if(keyDown(VKey)){
    drawCommand("Set brush strength");
    if(!keyJustPressed[VKey]){
      keyJustPressed[VKey]=true;
      xDragStart = mouseX;
      yDragStart = mouseY;
      xDragInit  = brushInfluence;
    }
    float dX = mouseX - xDragStart;
    float dY = mouseY - yDragStart;
    
    float innerRad = 20;
    float outerRad = 100;
    float magnitude = sqrt(dX*dX + dY*dY);
    magnitude = constrain(magnitude,innerRad, outerRad);
    //this is a better name, wish I thought of it earlier
    float newBrushStrength = constrain((outerRad-magnitude)/(outerRad - innerRad),0.05,1);
    //r/iamverysmart
    fill((col>>16) & 0xFF, (col>>8)&0xFF,(col>>4) & 0xFF, newBrushStrength*255);
    ellipse(xDragStart,yDragStart, 2*innerRad,2*innerRad);
    fill(0,0,0,0);
    ellipse(xDragStart,yDragStart, 2*outerRad,2*outerRad);
    ellipse(xDragStart,yDragStart, 2*magnitude,2*magnitude);
    line(xDragStart,yDragStart,mouseX,mouseY);
    if(!Float.isNaN(newBrushStrength)){
      brushInfluence = newBrushStrength;
    }
    
    return;
  }
    
  //change the repeating value
  if(keyDown(CKey)){
    drawCommand("Change frequency");
    if(!keyJustPressed[CKey]){
      keyJustPressed[CKey] = true;
      shiftChanged = true;
    }
    
    if(shiftChanged){
      shiftChanged = false;
      xDragStart = mouseX;
      xDragInit = localFrequency ? brushRepeating : brushFrequency;
    }
    
    if(localFrequency){
      float dX = (mouseX - xDragStart);
      if(keyDown(ShiftKey)){
        
        dX/=20f;
        drawCommand("slowly");
      }
      brushRepeating = constrain(xDragInit+dX,MINFREQUENCY,MAXFREQUENCY);
      drawRepeat(brushRepeating);
      drawCommand("local frequency: " + brushRepeating + " waves");
    } else {
      float dX = (mouseX - xDragStart)*20;
      if(keyDown(ShiftKey)){
        dX/=20;
        drawCommand("slowly");
      }
      brushFrequency = constrain(xDragInit+dX,MINFREQUENCY,MAXFREQUENCY);
      drawCommand("actual frequency: " + brushFrequency + "Hz");
    }
    
    line(xDragStart,yDragStart,mouseX,yDragStart);
    return;
  } 
  
  //change the brush
  if(keyDown(BKey)){
    drawCommand("Change brush type");
    if(!keyJustPressed[BKey]){
      keyJustPressed[BKey] = true;
      if(currentTool==AMPBRUSH){
        brushShape ++;
        brushShape %= numBrushShapes;
      }
    }
    return;
  }
  
  //play the sound sample
  if(keyDown(PKey)){
    drawCommand("Play sample");
    if(!keyJustPressed[PKey]){
      keyJustPressed[PKey] = true;
      //play with AB repeat if shift
      if(keyDown(ShiftKey)){
        playSample(false);
      } else {
        playSample(true);
      }
    }
    return;
  }
  
  //reset the brush
  if(keyDown(RKey)){
    drawCommand("Reset brush parameters");
    if(!keyJustPressed[RKey]){
      keyJustPressed[RKey] = true;
      resetBrush();
    }
    return;
  }
  
  //toggle the tone
  if(keyDown(TKey)){
    if(currentTool==AMPBRUSH){
      drawCommand("enable/disable brush tone");
    }
    
    if(!keyJustPressed[TKey]){
      keyJustPressed[TKey] = true;
      if(currentTool==AMPBRUSH){
        brushUseTone = !brushUseTone;
        return;
      }
    }
    return;
  } 
  
  //export a sound file
  if(keyDown(FSlashKey)){
    if(!keyJustPressed[FSlashKey]){
      keyJustPressed[FSlashKey] = true;
      
      drawCommand("Exporting WAV...");
      lastFilename = "Sample "+year()+"-"+month()+"-"+day()+"-"+second()+millis()+".wav";
      exportFileWav(lastFilename);
    }
    drawCommand("EXPORTED A WAV FILE!: " + lastFilename);
    return;
  } 
  
  
  //F key, maybe bind it to something else
  if(keyDown(FKey)){
    drawCommand("Change tone type");
    if(!keyJustPressed[FKey]){
      keyJustPressed[FKey] = true;
      
      currentTone ++;
      currentTone %= toneNames.length;
    } 
    
    return;
  } 
  
  if(keyDown(TabKey)){
    drawCommand("Change tool type");
    if(!keyJustPressed[TabKey]){
      keyJustPressed[TabKey] = true;
      currentTool++;
      currentTool %= numTools;
    } 
    drawCommand("to "+toolNames[currentTool]);
    return;
  } 
  
  //this doesn't even work :(
  if(keyDown(CtrlKey)){
    //lol
    if(keyDown(ZKey)){
      drawCommand("ctrl-z haha funny joke");
    }else if(keyDown(SKey)){
      drawCommand("Press [/] to save the wav file instead, Shift-S is being used to zoom out\nand it's too close to Ctrl-S");
    }
  }
}

int finalFrame = 0;
int initFrame = 0;

void playSample(boolean ab){  
  if(!sample.isPlaying()){
    sample.amp(1);
    if(ab==false){
      sample.cue(0);
      initFrame = 0;
      finalFrame = sample.frames();
    }else{
      sample.cue(cursorA/(float)FPS);
      initFrame = cursorA;
      finalFrame = cursorB;
    }
    sample.play();
  }
}


void stopSample(){
  sample.stop();
}

//initially made this to draw 1 triangle, might keep it for other more complex shapes
void drawArrays(float[] xPoints, float[] yPoints){
  for(int i = 0; i < xPoints.length;i++){
    if(i<xPoints.length-1){
      line(xPoints[i],yPoints[i],xPoints[i+1], yPoints[i+1]);
    } else {
      line(xPoints[i],yPoints[i],xPoints[0], yPoints[0]);
    }
  }
}

boolean drawButton(float x, float y, float w, float h){
  boolean result = false;
  noFill();
  if(mouseInside(x,y,w,h)){
    if(mousePressed){
      result = true;
      fill(buttonPressFill);
    } else{
      fill(buttonFill);
    }
  }
  rect(x,y,w,h);
  return result;
}

void drawButtons(color bgFill){
  float w = 40,h = 40;
  float padding = 5;
  float x=width-padding-w,y=height-padding-h;
  
  if(drawButton(x,y,w,h)){
    //play with AB repeat if shift
    if(keyDown(ShiftKey)){
      playSample(false);
    } else {
      playSample(true);
    }
  }
  fill(bgFill);
  //a trianlge for the play button
  if(keyDown(ShiftKey)){
    triangle(x+2,y+2,x+2,y+h-2,x+w-2,y+h/2);
  } else {
    triangle(x+8,y+8,x+8,y+h-8,x+w-8,y+h/2);
    text("A",x+2,y+h-2);
    text("B",x+w-7,y+h-2);
  }
  
  x -= w + 2*padding;

  if(drawButton(x,y,w,h)){
    stopSample();
  }
  
  fill(bgFill);
  //a square for the stop button. ye ik i could have used rect
  rect(x+4,y+4,w-8,h-8);
  
  x -= w + 2*padding;
  
  //draw more buttons
}

void drawWidthDimension(){    
    line(brushX()-brushWidth,height/4 - 30,brushX()-brushWidth,height/4-45);
    line(brushX()+brushWidth,height/4 - 30,brushX()+brushWidth,height/4-45);
    line(brushX()-brushWidth,height/4-40,brushX()+brushWidth,height/4-40);
    
    textAlign(CENTER);
    int numSamples = round(2*windowSize*(brushWidth/width));
    text("[z+mouseX] width: "+numSamples+"F("+nf(numSamples/(float)FPS,0,DISPLAYPRECISION)+"s)",brushX(), height/4-50);
    textAlign(LEFT);
}

void drawToolInfo(){
  textAlign(LEFT);
  float v = height-95;
  float h = 10;

  textSize(16);
  text("TOOL: " + toolNames[currentTool], h,v);
  textSize(12);
  v+=15;
  if(currentTool==AMPBRUSH){
    text("[b] brush shape: "+brushShapes[brushShape],h,v);
    v+=10;
    drawWidthDimension();
    
    text("[z+mouseY] height: "+brushHeight(),h,v);
    v+=10;
    
    text("[x] shear: "+brushShear,h,v);
    v+=10;
    
    text("[v] influence: "+brushInfluence,h,v);
    v+=10;
    
    text("[t] use tone?: "+str(brushUseTone),h,v);
    v+=10;
    
    if(brushUseTone){
      text("[f] tone type: "+toneNames[currentTone],h,v);
      v+=10;
      text("[c] frequency: "+brushFrequency,h,v);
      v+=10;
    }
  } else if(currentTool==NOISEBRUSH){
    drawWidthDimension();
    text("[z+mouseY] height: "+brushHeight(),h,v);
    v+=10;
    
    text("[v] influence: "+brushInfluence,h,v);
    v+=10;
  } else if(currentTool==CLONEBRUSH){
    text("ab width: " + (cursorB - cursorA), h, v);
    v+=10;
    text("ab width in time: " + nf((cursorB - cursorA)/(float)FPS,0,DISPLAYPRECISION), h, v);
  }
}

//>brushVars
String[] toneNames = {"Sinewave", "Triangle Wave", "Square Wave", "SawTooth"};
final int SINETONE = 0;
final int TRITONE = 1;
final int SQUARETONE = 2;
final int SAWTOOTHTONE = 3;

int currentTone = 1;//the tone type to generate
float brushWidth = 10;//how wide the curve is
float brushHeight = 50;//the amplitude of the curve
float brushHeight() { return brushHeight/(height/4); }
float brushShear = 0;//How much a linear equation is added to it
float brushInfluence = 1;//how much a click influences the samples. think proportinoal editing
float brushFrequency = 5000;//how many colinear repetitions of the curve are used per second
float brushRepeating = 1;//local repetition
float brushRotation = 0;
boolean brushUseTone = false;

String[] brushShapes = {"Line","Circle","Sinewave"};
int brushShape = 1;
final int LINEBRUSH = 0;
final int CIRCLEBRUSH = 1;
final int SINEBRUSH = 2;
final int numBrushShapes = 3;

boolean localFrequency = false; 

void resetBrush(){
  brushWidth = 10;
  brushHeight = 50;
  brushShear = 0;
  brushInfluence = 0.1;
  brushFrequency = 5000;
  brushRepeating = 1;
}

//>brushFunctions
float BrushCircle(float x){
  x=constrain(x,-1,1);
  return sqrt(1-x*x);
}

float BrushSawtooth(float x){
  x = wrap(x,-1,1);
  return x;
}

float BrushSine(float x){
  return sin(PI*x*0.5);
}

float BrushTriangle(float x){
  x = wrap(x,-1,1);
  if(x<0){
    return 2*(x + 1)-1;
  } else {
    return -1.0 -2*(x-1);
  }
}

float BrushSquare(float x){
  x=wrap(x,-1,1);
  if(abs(x)>0.5f){
    return -1f;
  }
  return 1f;
}

float wrap(float val, float min, float max){
  if(val > max){
    return abs(val-max)%abs(min-max)+min;
  } else if (val < min){
    return max - abs(val-min)%abs(min-max);
  } else {
    return val;
  }
}

float sqrMagnitude(float x1, float y1){
  return x1*x1+y1*y1;
}

void drawShear(float x){
  float w = height;
  line(mouseX+w, mouseY+x*w,mouseX-w, mouseY-x*w);
}

void drawWidth(float x, float h){
  line(mouseX-x, mouseY+h,mouseX-x, mouseY-h);
  line(mouseX+x, mouseY+h,mouseX+x, mouseY-h);
}

void drawRepeat(float x){
  text("x"+x, mouseX,mouseY);
}


float brushX(){
  return mouseX;
}

float brushY(){
  if(keyDown(SpaceKey)){
    return height/2;
  }
  if(currentTool==1){
    return height/2;
  }
  return mouseY;
}

//these are blend modes for combining two samples
final int bNONE = -1;
final int bADD = 0;
final int bSUBTRACT = 2;
final int bAVERAGE = 3;
final int bMAX = 4;
final int bMIN = 5;
final int bSIGN = 6;
final int bDISTANCE = 7;
final int bSAMPLEDISTANCE = 8;

int[] lerpBlends = {bADD, bSUBTRACT, bAVERAGE, bSIGN, bAVERAGE, bSAMPLEDISTANCE};
int[] noiseBlends = {bADD, bSIGN, bSAMPLEDISTANCE};
int brushAttractionBlend = 0;
int brushLerpBlend = 0;
int brushNoiseBlend = 0;

float combineNumbers(float a, float b, int type){
  switch(type){
    case bADD:{
      return a+b;
    } case bSUBTRACT:{
      return a-b;
    } case bDISTANCE:{
      return abs(a-b);
    } case bSAMPLEDISTANCE:{
      return abs(abs(a) - abs(b));
    } case bAVERAGE:{
      return a/2+b/2;
    } case bMAX:{
      return max(a,b);
    } case bMIN:{
      return min(a,b);
    } case bSIGN:{
      return abs(a) * sign(b);
    } default: {
      return a;
    }
  }
}

//>draw functions
//all new boi, will be half the program
void sampleDrawTool(boolean use){    
  float brushX = brushX();
  float brushY = brushY();
  //draw brush
  if(brushUseTone){
    text("[c] "+brushFrequency+"hZ"+"("+ musicalNote(brushFrequency) +")", mouseX, mouseY-10);
    text("[f] "+toneNames[currentTone], mouseX, mouseY+10);
  }
  noFill();
  switch(brushShape){
    case CIRCLEBRUSH:{
      ellipse(brushX, brushY, 2*brushWidth, 2*brushWidth);
      break;
    } case LINEBRUSH: {
      line(brushX-brushWidth, brushY-brushShear*brushWidth,brushX+brushWidth,brushY+brushShear*brushWidth);
      break;
    } case SINEBRUSH: {
      for(float f = -brushWidth; f < brushWidth; f+=1){
        line(f+brushX,BrushSine(f/brushWidth)*brushHeight+brushY,f+1+brushX,BrushSine((f+1)/brushWidth)*brushHeight+brushY);
      }
      break;
    } 
  }
  
  if(!use){
    return;
  }
  
  int startSample = toWaveformX(brushX-brushWidth);
  int endSample = toWaveformX(brushX+brushWidth);
  int actualStartSample = max(startSample,0);
  int actualEndSample = min(endSample, sample.frames());
  for(int x = actualStartSample; x < actualEndSample; x++){
    float brushPosition = 2*(float)(x-startSample)/(float)abs(endSample-startSample)-1;
    float wantedSampleValue = 0;
    
    switch(brushShape){
    case CIRCLEBRUSH:{
        float value = -BrushCircle(brushPosition)*brushWidth -brushShear * brushPosition;
        wantedSampleValue = toWaveformY(value+brushY);
        //ellipse(brushX, brushY, 2*brushWidth, 2*brushHeight);
        break;
      } case LINEBRUSH: {
        float value = brushShear * (brushWidth * brushPosition);
        wantedSampleValue = toWaveformY(value+brushY);
        break;
      } case SINEBRUSH: {
        float value = BrushSine(brushPosition)*brushHeight -brushShear * brushPosition;
        wantedSampleValue = toWaveformY(value+brushY);
        break;
      } 
    }
    
    float xTime = (x)/(float)FPS * brushFrequency;
    float existingSample = sample.read(x);
    
    if(brushUseTone){
      float multFactor = 0;
      switch(currentTone){
        case SINETONE:{
          multFactor = BrushSine(xTime);
          break;
        } case SQUARETONE:{
          multFactor = BrushSquare(xTime);
          break;
        } case TRITONE:{
          multFactor = BrushTriangle(xTime);
          break;
        } case SAWTOOTHTONE: {
          multFactor = BrushSawtooth(xTime);
          break;
        }
      }
      wantedSampleValue *= multFactor;
    } else {
      wantedSampleValue = abs(wantedSampleValue)*sign(existingSample);
    }
    
    
    wantedSampleValue = constrain(wantedSampleValue,-1,1);
    sample.write(x,lerp(existingSample,wantedSampleValue,brushInfluence*brushInfluence));
  }
}

void sampleNoiseTool(boolean use){
  noFill();
  float brushX = brushX();
  float brushY = brushY();
  //draw brush
  float prevY = 0;
  float spacing = brushWidth/6;
  brushHeight = abs(brushHeight);
  for(float f = -brushWidth; f < brushWidth; f+= spacing){
    float temp = random(-abs(brushHeight),abs(brushHeight));
    line(brushX+f,brushY + prevY,brushX+f+spacing,brushY+temp);
    prevY=temp;
  }
  line(brushX-brushWidth, brushY+brushHeight, brushX-brushWidth,brushY-brushHeight);
  line(brushX+brushWidth, brushY+brushHeight, brushX+brushWidth,brushY-brushHeight);
  
  if(!use){
    return;
  }
  
  int startSample = max(toWaveformX(brushX-brushWidth),0);
  int endSample = min(toWaveformX(brushX+brushWidth),sample.frames());
  for(int x = startSample; x < endSample; x++) {
    float existingSample = sample.read(x);
    float wantedSampleValue;
    wantedSampleValue = random(-brushHeight(),brushHeight());
    wantedSampleValue = constrain(wantedSampleValue,-1,1);
    sample.write(x,lerp(existingSample,wantedSampleValue,brushInfluence));
  }
}

//was used by another tool but no longer needed
void drawWheel(float x, float y, float r, float rotation, int numSpokes){
  ellipse(x, y, 2*brushWidth, 2*brushWidth);
  line(x-r, y+height/4, x-r,y-height/4);
  line(x+r, y+height/4, x+r,y-height/4);
  for(int i = 0; i < numSpokes; i++){
    float angle = rotation + 2*PI*i/numSpokes;
    float xGrad = cos(angle);
    float yGrad = sin(angle);
    line(x-xGrad*r,y-yGrad*r,x-xGrad*r*2/3,y-yGrad*r*2/3);
  }
}

void sampleCloneBrush(boolean use, boolean flip){
  float brushX = brushX();
  int abWidth = cursorB - cursorA;
  int startSample = toWaveformX(brushX)-abWidth/2;
  int endSample = toWaveformX(brushX)+abWidth/2;
  if(startSample < 0){
    startSample = 0;
    endSample = startSample + abWidth;
  }
  
  if(endSample > sample.frames()){
    endSample = sample.frames();
    startSample = endSample - abWidth;
  }
  
  //(start and end < A) or (start and end) > b) 
  boolean useable = ((startSample < cursorA)&&((endSample < cursorA)))||((endSample > cursorB)&&(startSample > cursorB));
  
  if(!useable)
    stroke(disabledToolColor);
  
  strokeWeight(2);
  drawCursor("A clone", startSample, -height/4+50);
  drawCursor("B clone", endSample, height/4-50);
  strokeWeight(1);
  
  if((!useable)||(!use))
    return;
  
  for(int x = startSample; x < endSample; x++){
    float existingSample = sample.read(x);
    float wantedSampleValue = sample.read(cursorA + x - startSample);
    if(flip){
      sample.write(endSample - (x - startSample)-1,lerp(existingSample,wantedSampleValue,brushInfluence));
    } else {
      sample.write(x,lerp(existingSample,wantedSampleValue,brushInfluence));
    }
  }
}

void drawTool(boolean lmb, boolean rmb){
  // disable brush if outside hotzone
  if(!mouseInside(toScreenX(0)-brushWidth,height/4 - 50,abs(toScreenX(0)-toScreenX(sample.frames()))+2*brushWidth,height/2 + 100)){
    fill(disabledToolColor);
    stroke(disabledToolColor);
    lmb=false;
    rmb=false;
  }
  
  if(currentTool==AMPBRUSH){
    sampleDrawTool(lmb);
    lmb = false;
  } else if (currentTool==NOISEBRUSH){
    sampleNoiseTool(lmb);
    lmb = false;
  } else if (currentTool==CLONEBRUSH){
    sampleCloneBrush(lmb||rmb, rmb);
    lmb=false;
    rmb=false;
  }
  
  if(rmb){
    placeCursor();
  }
}

boolean isPlaying = false;
int t0 = 0;//used to show the playback cursor

//change them later
final int AMPBRUSH = 0;
final int NOISEBRUSH = 1;
final int CLONEBRUSH = 2;

String[] toolNames = {"Brush","Noise generater", "Clone tool"};  
int currentTool = 0;
int numTools = 3;


int cursorA = 0;
int cursorB = 1;

void drawCursor(String text, int position, float h){
  float tempX = toScreenX(position);
  if((tempX<0)||(tempX>width))
    return;
    
  line(tempX,height/2, tempX, height/2+h);
  text(text,tempX,height/2+h+sign(h)*10);
}

void addNewSamplesOpt(boolean yes){
  float tempX = toScreenX(sample.frames());
  line(tempX,height/4,tempX,height-height/4);
  float tempX2 = toScreenX(sample.frames()+FPS);
  line(tempX2,height/4,tempX2,height-height/4);
  textAlign(LEFT);
  textSize(30);
  text("[ADD 1 second]", tempX + 10, height/2);
  textSize(12);
  if(yes){
    //add 1 second of noise onto the end
    AudioSample temp = sample;
    sample = new AudioSample(this,new float[sample.frames()+FPS],FPS);
    for(int i = 0; i < sample.frames(); i++){
      if(i < temp.frames()){
        sample.write(i,temp.read(i));
      } else {
        sample.write(i, random(-1,1));
      }
    }
    return;
  }
}

void drawCursors(){
  strokeWeight(2);
  if(mouseY < height/2){
    stroke(activeCursorColor);
    fill(activeCursorColor);
    drawCursor("A: "+cursorA+"("+nf(cursorA/(float)FPS,0,DISPLAYPRECISION)+")", cursorA, -height/4);
    
    stroke(cursorColor);
    fill(cursorColor);
    drawCursor("B: "+cursorB+"("+nf(cursorB/(float)FPS,0,DISPLAYPRECISION)+")", cursorB, height/4);
  } else {
    stroke(activeCursorColor);
    fill(activeCursorColor);
    drawCursor("B: "+cursorB+"("+nf(cursorB/(float)FPS,0,DISPLAYPRECISION)+")", cursorB, height/4);
    
    stroke(cursorColor);
    fill(cursorColor);
    drawCursor("A: "+cursorA+"("+nf(cursorA/(float)FPS,0,DISPLAYPRECISION)+")", cursorA, -height/4);
  }
  strokeWeight(1);
}

void placeCursor(){  
  //place a cursor based on mouse Y
  int temp = toWaveformX(mouseX);
  temp=constrain(temp,0,sample.frames()-1);
  if(mouseY < height/2){
    if(temp < cursorB){
      cursorA = temp;
    } else {
      drawCommand("Cursor A must be placed\n before cursor B");
    }
  } else {
    if(cursorA < temp){
      cursorB = temp;
    }else{
      drawCommand("Cursor B must be placed\n after cursor A");
    }
  }
}

void draw() {
  background(backgroundColor);
  stroke(waveformColor);
  drawWaveform();
  
  stroke(axesColor);
  fill(axesColor);
  drawAxes();
  
  stroke(axesColor);
  fill(axesColor);
  drawRuler();
  
  stroke(sampleInfoColor);
  fill(sampleInfoColor);
  drawSampleInfo();
  
  drawCursors();
  
  stroke(toolColor);
  fill(toolColor);
  
  float newSamplesX = toScreenX(sample.frames())+brushWidth+5;
  float newSamplesXEnd = toScreenX(sample.frames()+FPS)+brushWidth+5; 
  if(mouseInside(newSamplesX,height/4,newSamplesXEnd - newSamplesX, height/2)) {
    //add 1 second if mousePressed
    addNewSamplesOpt(mousePressed);
  } else {
    drawTool(mousePressed&&(mouseButton==LEFT),mousePressed&&(mouseButton==RIGHT));
  }
  
  fill(toolColor);
  drawToolInfo();
  
  handleKeyInput(commandColor);
  
  drawButtons(toolColor);
  
  stroke(playCursorColor);
  strokeWeight(2);
  trackPlayback();
  strokeWeight(1);
}

void trackPlayback(){
  //draw the playback if needed
  if(sample.isPlaying()){
    if(!isPlaying){
      isPlaying = true;
      t0 = millis();
    }
    
    int currentPos = ((millis() - t0) * FPS)/1000 + initFrame;
    if(currentPos > finalFrame){
      stopSample();
    } else {
      float lineXPos = toScreenX(currentPos);
      line(lineXPos,height/4,lineXPos,height-height/4);
    }
  } else {
    isPlaying = false;
  }
}