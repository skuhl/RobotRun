import controlP5.*;

import java.util.*;
import java.nio.*;

ArmModel testModel;
float lastMouseX, lastMouseY;
float cameraTX = 0, cameraTY = 0, cameraTZ = 0;
float cameraRX = 0, cameraRY = 0, cameraRZ = 0;
boolean spacebarDown = false;
float[] jointsMoving = new float[6];

ControlP5 cp5;
Textarea myTextarea;
Accordion accordion;

ArrayList<Program> tasks = new ArrayList<Program>();

/* global variables for toolbar */
// for pan button
int cursorMode = ARROW;
int clickPan = 0;
float panX = 1.0; 
float panY = 1.0;
boolean doPan = false;

// for rotate button
int clickRotate = 0;
float myRotX = 0.0;
float myRotY = 0.0;
boolean doRotate = false;

float myscale = 0.5;
/*******************************/
     


public void setup(){
  size(1200, 800, P3D);
  cp5 = new ControlP5(this);
  gui();
  for (int n = 0; n < registers.length; n++) registers[n] = new PVector();
  for (int n = 0; n < 6; n++) jointsMoving[n] = 0;
  testModel = new ArmModel(ARM_TEST);
}

public void draw(){
  moveJoints();
  cursor(cursorMode);
  hint(ENABLE_DEPTH_TEST);
  background(255);
  stroke(100, 100, 255);
  noFill();
  pushMatrix();
  
  // camera controls
  translate(width/1.5,height/1.5);
  translate(panX, panY); // for pan button
  //rotateX(PI);
  scale(myscale);
  rotateX(myRotX); // for rotate button
  rotateY(myRotY); // for rotate button
  // end camera controls
  
  pushMatrix();
  testModel.draw();
  popMatrix();
  
  PVector eep = calculateEndEffectorPosition(testModel, false);
  popMatrix();
  
  // start test
  
  pushMatrix();
  translate(eep.x, eep.y, eep.z);
  stroke(255, 0, 0);
  sphere(25);
  popMatrix();
  // end test
  
  hint(DISABLE_DEPTH_TEST);
}


