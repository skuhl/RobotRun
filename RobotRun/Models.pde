import java.util.concurrent.ArrayBlockingQueue;

//To-do list:
//Collision detection

public class Triangle {
  // normal, vertex 1, vertex 2, vertex 3
  public PVector[] components = new PVector[4];
}

public class Model {
  public PShape mesh;
  public String name;
  public boolean[] rotations = new boolean[3]; // is rotating on this joint valid?
  // Joint ranges follow a clockwise format running from the PVector.x to PVector.y, where PVector.x and PVector.y range from [0, TWO_PI]
  public PVector[] jointRanges = new PVector[3];
  public float[] currentRotations = new float[3]; // current rotation value
  public float[] targetRotations = new float[3]; // we want to be rotated to this value
  public int[] rotationDirections = new int[3]; // control rotation direction so we
                                                // don't "take the long way around"
  public float rotationSpeed;
  public float[] jointsMoving = new float[3]; // for live control using the joint buttons
  
  public Model(String filename, color col) {
    for (int n = 0; n < 3; n++) {
      rotations[n] = false;
      currentRotations[n] = 0;
      jointRanges[n] = null;
    }
    rotationSpeed = 0.01;
    name = filename;
    loadSTLModel(filename, col);
  }
  
  void loadSTLModel(String filename, color col) {
    ArrayList<Triangle> triangles = new ArrayList<Triangle>();
    byte[] data = loadBytes(filename);
    int n = 84; // skip header and number of triangles
    
    while (n < data.length) {
      Triangle t = new Triangle();
      for (int m = 0; m < 4; m++) {
        byte[] bytesX = new byte[4];
        bytesX[0] = data[n+3]; bytesX[1] = data[n+2];
        bytesX[2] = data[n+1]; bytesX[3] = data[n];
        n += 4;
        byte[] bytesY = new byte[4];
        bytesY[0] = data[n+3]; bytesY[1] = data[n+2];
        bytesY[2] = data[n+1]; bytesY[3] = data[n];
        n += 4;
        byte[] bytesZ = new byte[4];
        bytesZ[0] = data[n+3]; bytesZ[1] = data[n+2];
        bytesZ[2] = data[n+1]; bytesZ[3] = data[n];
        n += 4;
        t.components[m] = new PVector(
          ByteBuffer.wrap(bytesX).getFloat(),
          ByteBuffer.wrap(bytesY).getFloat(),
          ByteBuffer.wrap(bytesZ).getFloat()
        );
      }
      triangles.add(t);
      n += 2; // skip meaningless "attribute byte count"
    }
    mesh = createShape();
    mesh.beginShape(TRIANGLES);
    mesh.noStroke();
    mesh.fill(col);
    for (Triangle t : triangles) {
      mesh.normal(t.components[0].x, t.components[0].y, t.components[0].z);
      mesh.vertex(t.components[1].x, t.components[1].y, t.components[1].z);
      mesh.vertex(t.components[2].x, t.components[2].y, t.components[2].z);
      mesh.vertex(t.components[3].x, t.components[3].y, t.components[3].z);
    }
    mesh.endShape();
  } // end loadSTLModel
    
  public boolean anglePermitted(int idx, float angle) {
    
    if (jointRanges[idx].x < jointRanges[idx].y) {
      // Joint range does not overlap TWO_PI
      return angle >= jointRanges[idx].x && angle < jointRanges[idx].y;
    } else {
      // Joint range overlaps TWO_PI
      return !(angle >= jointRanges[idx].y && angle < jointRanges[idx].x);
    }
  }
  
  public void draw() {
    shape(mesh);
  }
  
} // end Model class

// The apporximate center of the base of the robot
public static final PVector base_center = new PVector(404, 137, -212);

public class ArmModel {
  
  public ArrayList<Model> segments = new ArrayList<Model>();
  public int type;
  //public boolean calculatingArms = false, movingArms = false;
  public float motorSpeed;
  // Indicates translational motion in the World Frame
  public float[] mvLinear = new float[3];
  // Indicates rotational motion in the World Frame
  public float[] mvRot = new float[3];
  public float[] tgtRot = new float[4];
  public PVector tgtPos = new PVector();
      
  public Object held;
  public float[][] oldEETMatrix;
  
  public ArmModel() {
    
    motorSpeed = 4000.0; // speed in mm/sec
    // Joint 1
    Model base = new Model("ROBOT_MODEL_1_BASE.STL", color(200, 200, 0));
    base.rotations[1] = true;
    base.jointRanges[1] = new PVector(0, TWO_PI);
    base.rotationSpeed = radians(350)/60.0;
    // Joint 2
    Model axis1 = new Model("ROBOT_MODEL_1_AXIS1.STL", color(40, 40, 40));
    axis1.rotations[2] = true;
    axis1.jointRanges[2] = new PVector(4.34, 2.01);
    axis1.rotationSpeed = radians(350)/60.0;
    // Joint 3
    Model axis2 = new Model("ROBOT_MODEL_1_AXIS2.STL", color(200, 200, 0));
    axis2.rotations[2] = true;
    axis2.jointRanges[2] = new PVector(12f * PI / 20f, 8f * PI / 20f);
    axis2.rotationSpeed = radians(400)/60.0;
    // Joint 4
    Model axis3 = new Model("ROBOT_MODEL_1_AXIS3.STL", color(40, 40, 40));
    axis3.rotations[0] = true;
    axis3.jointRanges[0] = new PVector(0, TWO_PI);
    axis3.rotationSpeed = radians(450)/60.0;
    // Joint 5
    Model axis4 = new Model("ROBOT_MODEL_1_AXIS4.STL", color(40, 40, 40));
    axis4.rotations[2] = true;
    axis4.jointRanges[2] = new PVector(59f * PI / 40f, 11f * PI / 20f);
    axis4.rotationSpeed = radians(450)/60.0;
    // Joint 6
    Model axis5 = new Model("ROBOT_MODEL_1_AXIS5.STL", color(200, 200, 0));
    axis5.rotations[0] = true;
    axis5.jointRanges[0] = new PVector(0, TWO_PI);
    axis5.rotationSpeed = radians(720)/60.0;
    Model axis6 = new Model("ROBOT_MODEL_1_AXIS6.STL", color(40, 40, 40));
    segments.add(base);
    segments.add(axis1);
    segments.add(axis2);
    segments.add(axis3);
    segments.add(axis4);
    segments.add(axis5);
    segments.add(axis6);
    
    for (int idx = 0; idx < mvLinear.length; ++idx) {
      mvLinear[idx] = 0;
    }
    
    for (int idx = 0; idx < mvRot.length; ++idx) {
      mvRot[idx] = 0;
    }
    
    held = null;
    // Initializes the old transformation matrix for the arm model
    pushMatrix();
    applyModelRotation(this);
    oldEETMatrix = getTransformationMatrix();
    popMatrix();
  } // end ArmModel constructor
  
  public void draw() {
    
    noStroke();
    fill(200, 200, 0);
    
    translate(600, 200, 0);

    rotateZ(PI);
    rotateY(PI/2);
    segments.get(0).draw();
    rotateY(-PI/2);
    rotateZ(-PI);
    
    fill(50);
  
    translate(-50, -166, -358); // -115, -213, -413
    rotateZ(PI);
    translate(150, 0, 150);
    rotateY(segments.get(0).currentRotations[1]);
    translate(-150, 0, -150);
    segments.get(1).draw();
    rotateZ(-PI);
  
    fill(200, 200, 0);
  
    translate(-115, -85, 180);
    rotateZ(PI);
    rotateY(PI/2);
    translate(0, 62, 62);
    rotateX(segments.get(1).currentRotations[2]);
    translate(0, -62, -62);
    segments.get(2).draw();
    rotateY(-PI/2);
    rotateZ(-PI);
  
    fill(50);
 
    translate(0, -500, -50);
    rotateZ(PI);
    rotateY(PI/2);
    translate(0, 75, 75);
    rotateX(segments.get(2).currentRotations[2]);
    translate(0, -75, -75);
    segments.get(3).draw();
    rotateY(PI/2);
    rotateZ(-PI);
  
    translate(745, -150, 150);
    rotateZ(PI/2);
    rotateY(PI/2);
    translate(70, 0, 70);
    rotateY(segments.get(3).currentRotations[0]);
    translate(-70, 0, -70);
    segments.get(4).draw();
    rotateY(-PI/2);
    rotateZ(-PI/2);
  
    fill(200, 200, 0);
  
    translate(-115, 130, -124);
    rotateZ(PI);
    rotateY(-PI/2);
    translate(0, 50, 50);
    rotateX(segments.get(4).currentRotations[2]);
    translate(0, -50, -50);
    segments.get(5).draw();
    rotateY(PI/2);
    rotateZ(-PI);
  
    fill(50);
  
    translate(150, -10, 95);
    rotateY(-PI/2);
    rotateZ(PI);
    translate(45, 45, 0);
    rotateZ(segments.get(5).currentRotations[0]);
    translate(-45, -45, 0);
    segments.get(6).draw();
          
    // next, the end effector
    if (activeEndEffector == ENDEF_SUCTION) {
      rotateY(PI);
      translate(-88, -37, 0);
      eeModelSuction.draw();
    } else if (activeEndEffector == ENDEF_CLAW) {
      rotateY(PI);
      translate(-88, 0, 0);
      eeModelClaw.draw();
      rotateZ(PI/2);
      if (endEffectorStatus == OFF) {
        translate(10, -85, 30);
        eeModelClawPincer.draw();
        translate(55, 0, 0);
        eeModelClawPincer.draw();
      } else if (endEffectorStatus == ON) {
        translate(28, -85, 30);
        eeModelClawPincer.draw();
        translate(20, 0, 0);
        eeModelClawPincer.draw();
      }
    }
  }//end draw arm model
  
  //returns the rotational values for each arm joint
  public float[] getJointRotations() {
    float[] rot = new float[6];
    for (int i = 0; i < segments.size(); i += 1) {
      for (int j = 0; j < 3; j += 1) {
        if (segments.get(i).rotations[j]) {
          rot[i] = segments.get(i).currentRotations[j];
          break;
        }
      }
    }
    return rot;
  }//end get joint rotations
  
  /* Calculate and returns a 3x3 matrix whose columns are the unit vectors of
   * the end effector's current x, y, z axes with respect to the world frame.
   */
  public float[][] getRotationMatrix() {
    pushMatrix();
    resetMatrix();
    // Switch to End Effector reference Frame
    applyModelRotation(armModel);
    /* Define vectors { 0, 0, 0 }, { 1, 0, 0 }, { 0, 1, 0 }, and { 0, 0, 1 }
     * Swap vectors:
     *   x' = z
     *   y' = x
     *   z' = y
     */
    PVector origin = new PVector(modelX(0, 0, 0), modelY(0, 0, 0), modelZ(0, 0, 0)),
            
            x = new PVector(modelX(0, 0, -1), modelY(0, 0, -1), modelZ(0, 0, -1)),
            y = new PVector(modelX(0, 1, 0), modelY(0, 1, 0), modelZ(0, 1, 0)),
            z = new PVector(modelX(1, 0, 0), modelY(1, 0, 0), modelZ(1, 0, 0));
            
    float[][] matrix = new float[3][3];
    // Calcualte Unit Vectors form difference between each axis vector and the origin
  
    matrix[0][0] = x.x - origin.x;
    matrix[0][1] = x.y - origin.y;
    matrix[0][2] = x.z - origin.z;
    matrix[1][0] = y.x - origin.x;
    matrix[1][1] = y.y - origin.y;
    matrix[1][2] = y.z - origin.z;
    matrix[2][0] = z.x - origin.x;
    matrix[2][1] = z.y - origin.y;
    matrix[2][2] = z.z - origin.z;
    
    popMatrix();
    
    return matrix;
  }
  
 /* This method calculates the Euler angular rotations: roll, pitch and yaw of the Robot's
  * End Effector in the form of a vector array.
  *
  * @param axesMatrix  A 3x3 matrix containing unti vectors representing the Robot's End
  *                    Effector's x, y, z axes in respect of the World Coordinate Frame;
  * @returning         A array containing the End Effector's roll, pitch, and yaw, in that
  *                    order
  *
  *  Method based off of procedure outlined in the pdf at this location:
  *     http://www.staff.city.ac.uk/~sbbh653/publications/euler.pdf
  *     rotation about: x - psi, y - theta, z - phi
  */
  public PVector getWPR() {
    float theta1, theta2, psi1, psi2, phi1, phi2;
    PVector wpr, wpr2;
    
    float[][] r = getRotationMatrix();
    
    if(r[2][0] != 1 && r[2][0] != -1){
      //rotation about y-axis
      theta1 = -asin(r[2][0]);
      theta2 = PI - theta1;
      //rotation about x-axis
      psi1 = atan2(r[2][1]/cos(theta1), r[2][2]/cos(theta1));
      psi2 = atan2(r[2][1]/cos(theta2), r[2][2]/cos(theta2));
      //rotation about z-axis
      phi1 = atan2(r[1][0]/cos(theta1), r[0][0]/cos(theta1));
      phi2 = atan2(r[1][0]/cos(theta2), r[0][0]/cos(theta2));
    }
    else{
      phi1 = phi2 = 0;
      if(r[2][0] == -1){
        theta1 = theta2 = PI/2;
        psi1 = psi2 = phi1 + atan2(r[0][1], r[0][2]);
      }
      else{
        theta1 = theta2 = -PI/2;
        psi1 = psi2 = -phi1 + atan2(-r[0][1], -r[0][2]);
      }
    }
    
    wpr = new PVector(psi1, theta1, phi1);
    wpr2 = new PVector(psi2, theta2, phi2);
    
    return wpr;
  }
  
  public PVector getWPR(float[] testAngles){
    float[] origAngles = getJointRotations();
    setJointRotations(testAngles);
    
    PVector ret = getWPR();
    setJointRotations(origAngles);
    return ret;
  }
  
  //returns the rotational value of the robot as a quaternion
  public float[] getQuaternion(){
    float[][] m = getRotationMatrix();
    float[] q = new float[4];
    float tr = m[0][0] + m[1][1] + m[2][2];
    
    if(tr > 0){ 
      float S = sqrt(tr+1.0) * 2; // S=4*q[0] 
      q[0] = 0.25 * S;
      q[1] = (m[2][1] - m[1][2]) / S;
      q[2] = (m[0][2] - m[2][0]) / S; 
      q[3] = (m[1][0] - m[0][1]) / S; 
    } else if((m[0][0] > m[1][1]) & (m[0][0] > m[2][2])){ 
      float S = sqrt(1.0 + m[0][0] - m[1][1] - m[2][2]) * 2; // S=4*q[1] 
      q[0] = (m[2][1] - m[1][2]) / S;
      q[1] = 0.25 * S;
      q[2] = (m[0][1] + m[1][0]) / S; 
      q[3] = (m[0][2] + m[2][0]) / S; 
    } else if(m[1][1] > m[2][2]){ 
      float S = sqrt(1.0 + m[1][1] - m[0][0] - m[2][2]) * 2; // S=4*q[2]
      q[0] = (m[0][2] - m[2][0]) / S;
      q[1] = (m[0][1] + m[1][0]) / S; 
      q[2] = 0.25 * S;
      q[3] = (m[1][2] + m[2][1]) / S; 
    } else { 
      float S = sqrt(1.0 + m[2][2] - m[0][0] - m[1][1]) * 2; // S=4*q[3]
      q[0] = (m[1][0] - m[0][1]) / S;
      q[1] = (m[0][2] + m[2][0]) / S;
      q[2] = (m[1][2] + m[2][1]) / S;
      q[3] = 0.25 * S;
    }
    
    return q;
  }
  
  public float[] getQuaternion(float[] testAngles){
    float[] origAngles = getJointRotations();
    setJointRotations(testAngles);
    
    float[] ret = getQuaternion();
    setJointRotations(origAngles);
    return ret;
  }
  
  /**
   * Gives the current position of the end effector in
   * Processing native coordinates.
   * @param model Arm model whose end effector position to calculate
   * @param test Determines whether to use arm segments' actual
   *             rotation values or if we're checking trial rotations
   * @return The current end effector position
   */
  public PVector getEEPos() {
    pushMatrix();
    resetMatrix();
    
    translate(600, 200, 0);
    translate(-50, -166, -358); // -115, -213, -413
    rotateZ(PI);
    translate(150, 0, 150);
    
    rotateY(getJointRotations()[0]);
    
    translate(-150, 0, -150);
    rotateZ(-PI);    
    translate(-115, -85, 180);
    rotateZ(PI);
    rotateY(PI/2);
    translate(0, 62, 62);
    
    rotateX(getJointRotations()[1]);
    
    translate(0, -62, -62);
    rotateY(-PI/2);
    rotateZ(-PI);   
    translate(0, -500, -50);
    rotateZ(PI);
    rotateY(PI/2);
    translate(0, 75, 75);
    
    rotateX(getJointRotations()[2]);
    
    translate(0, -75, -75);
    rotateY(PI/2);
    rotateZ(-PI);
    translate(745, -150, 150);
    rotateZ(PI/2);
    rotateY(PI/2);
    translate(70, 0, 70);
    
    rotateY(getJointRotations()[3]);
    
    translate(-70, 0, -70);
    rotateY(-PI/2);
    rotateZ(-PI/2);    
    translate(-115, 130, -124);
    rotateZ(PI);
    rotateY(-PI/2);
    translate(0, 50, 50);
    
    rotateX(getJointRotations()[4]);
    
    translate(0, -50, -50);
    rotateY(PI/2);
    rotateZ(-PI);    
    translate(150, -10, 95);
    rotateY(-PI/2);
    rotateZ(PI);
    translate(45, 45, 0);
    
    rotateZ(getJointRotations()[5]);
    
    if (activeToolFrame >= 0 && activeToolFrame < toolFrames.length) {
      PVector tr = toolFrames[activeToolFrame].getOrigin();
      translate(tr.x, tr.y, tr.z);
    }
    PVector ret = new PVector(
      modelX(0, 0, 0),
      modelY(0, 0, 0),
      modelZ(0, 0, 0));
    
    popMatrix();
    return ret;
  } // end calculateEndEffectorPosition
  
  public PVector getEEPos(float[] testAngles){
    float[] origAngles = getJointRotations();
    setJointRotations(testAngles);
    
    PVector ret = getEEPos();
    setJointRotations(origAngles);
    return ret;
    
  }
  
  //convenience method to set all joint rotation values of the robot arm
      public void setJointRotations(float[] rot){
    for(int i = 0; i < segments.size(); i += 1){
      for(int j = 0; j < 3; j += 1){
        if(segments.get(i).rotations[j]){
          segments.get(i).currentRotations[j] = rot[i];
          segments.get(i).currentRotations[j] %= TWO_PI;
          if(segments.get(i).currentRotations[j] < 0){
            segments.get(i).currentRotations[j] += TWO_PI;
          }
        }
      }
    }
  }//end set joint rotations
  
  public boolean interpolateRotation(float speed) {
    boolean done = true;
    for (Model a : segments){
      for (int r = 0; r < 3; r++){
        if (a.rotations[r]){
          if (abs(a.currentRotations[r] - a.targetRotations[r]) > a.rotationSpeed*speed){
            done = false;
            a.currentRotations[r] += a.rotationSpeed * a.rotationDirections[r] * speed;
            a.currentRotations[r] = clampAngle(a.currentRotations[r]);
          }
        }
      } // end loop through rotation axes
    } // end loop through arm segments
    return done;
  } // end interpolate rotation
  
  void updateOrientation(){
    PVector u = new PVector(mvRot[0], mvRot[1], mvRot[2]);
    
    if(u.x != 0 || u.y != 0 || u.z != 0){
      tgtRot = rotateQuat(tgtRot, DEG_TO_RAD, u);
    }
  }

  void executeLiveMotion() {
    if (curCoordFrame == COORD_JOINT) {
      for (int i = 0; i < segments.size(); i += 1) {
        Model model = segments.get(i);
        
        for (int n = 0; n < 3; n++) {
          if (model.rotations[n]) {
            float trialAngle = model.currentRotations[n] +
              model.rotationSpeed * model.jointsMoving[n] * liveSpeed;
              trialAngle = clampAngle(trialAngle);
            
            if (model.anglePermitted(n, trialAngle)) {
              // Caculate the distance that the end effector is from the center of the robot's base
              PVector ee_pos = armModel.getEEPos();
              // This is not the exact center, it is a rough estimate 
              float dist = PVector.dist(ee_pos, base_center);
              
              /* If the End Effector is within a certain distance from the robot's base,
               * then determine if the given angle will bring the robot closer to the
               * base; if so then end the robot's movement, otherwise allow the robot to
               * continue moving. */
              if (dist < 405f) {
                
                float old_angle = model.currentRotations[n];
                model.currentRotations[n] = trialAngle;
                
                // Caculate the distance that the end effector is from the center of the robot's base for the test angle
                PVector new_ee_pos = armModel.getEEPos();
                float new_dist = PVector.dist(new_ee_pos, base_center);
                
                if (new_dist < dist) {
                  // end robot arm movement
                  model.currentRotations[n] = old_angle;
                  model.jointsMoving[n] = 0;
                }
              } 
              else {
                model.currentRotations[n] = trialAngle;
              }  
            } 
            else {
              model.jointsMoving[n] = 0;
            }
          }
        }
      }
      updateButtonColors();
    } else if (curCoordFrame == COORD_WORLD) {
      //only move if our movement vector is non-zero
      if(mvLinear[0] != 0 || mvLinear[1] != 0 || mvLinear[2] != 0 || 
         mvRot[0] != 0 || mvRot[1] != 0 || mvRot[2] != 0) {
        PVector move = new PVector(mvLinear[0], mvLinear[1], mvLinear[2]);
        //convert to user frame coordinates if currently in a user frame
        if (activeUserFrame >= 0 && activeUserFrame < userFrames.length) {
          PVector[] frame = userFrames[activeUserFrame].axes;
          move.y = -move.y;
          move.z = -move.z;
          move = vectorConvertTo(move, frame[0], frame[1], frame[2]);
        }
        
        float distance = motorSpeed/60.0 * liveSpeed;
        tgtPos.x += move.x * distance;
        tgtPos.y += move.y * distance;
        tgtPos.z += move.z * distance;
        updateOrientation();
        
        //println(lockOrientation);
        int r = calculateIKJacobian(tgtPos, tgtRot);
        if(r == EXEC_FAILURE){
          updateButtonColors();
          mvLinear[0] = 0;
          mvLinear[1] = 0;
          mvLinear[2] = 0;
          mvRot[0] = 0;
          mvRot[1] = 0;
          mvRot[2] = 0;
        }
      }
    }
  } // end execute live motion
  
  /* If an object is currently being held by the Robot arm, then release it */
  public void releaseHeldObject() {
    armModel.held = null;
  }
  
  /* Indicates that the Robot Arm is in Motion */
  public boolean modelInMotion() {
    for (Model m : segments) {
      for (int idx = 0; idx < m.jointsMoving.length; ++idx) {
        if (m.jointsMoving[idx] != 0) {
          return true;
        }
      }
    }
    
    return mvLinear[0] != 0 || mvLinear[1] != 0 || mvLinear[2] != 0 ||
           mvRot[0] != 0 || mvRot[1] != 0 || mvRot[2] != 0;
  }
  
} // end ArmModel class

void printCurrentModelCoordinates(String msg) {
  print(msg + ": " );
  print(modelX(0, 0, 0) + " ");
  print(modelY(0, 0, 0) + " ");
  print(modelZ(0, 0, 0));
  println();
}