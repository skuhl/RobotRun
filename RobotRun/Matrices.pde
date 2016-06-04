/* Transforms the given vector from the coordinate system defined by the given
 * transformation matrix. */
public PVector transform(PVector v, float[][] tMatrix) {
  if (tMatrix.length != 4 || tMatrix[0].length != 4) {
    return null;
  }
  
  PVector u = new PVector();
  
  u.x = v.x * tMatrix[0][0] + v.y * tMatrix[0][1] + v.z * tMatrix[0][2] + tMatrix[0][3];
  u.y = v.x * tMatrix[1][0] + v.y * tMatrix[1][1] + v.z * tMatrix[1][2] + tMatrix[1][3];
  u.z = v.x * tMatrix[2][0] + v.y * tMatrix[2][1] + v.z * tMatrix[2][2] + tMatrix[2][3];
  
  return u;
}

/**
 * Find the inverse of the given 4x4 Homogeneous Coordinate Matrix. 
 * 
 * This method is based off of the algorithm found on this webpage:
 *    https://web.archive.org/web/20130806093214/http://www-graphics.stanford.edu/courses/cs248-98-fall/Final/q4.html
 */
public float[][] invertHCMatrix(float[][] m) {
  if (m.length != 4 || m[0].length != 4) {
    return null;
  }
  
  float[][] inverse = new float[4][4];
  
  /* [ ux vx wx tx ] -1       [ ux uy uz -dot(u, t) ]
   * [ uy vy wy ty ]     =    [ vx vy vz -dot(v, t) ]
   * [ uz vz wz tz ]          [ wx wy wz -dot(w, t) ]
   * [  0  0  0  1 ]          [  0  0  0      1     ]
   */
  inverse[0][0] = m[0][0];
  inverse[0][1] = m[1][0];
  inverse[0][2] = m[2][0];
  inverse[0][3] = -(m[0][0] * m[0][3] + m[1][0] * m[1][3] + m[2][0] * m[2][3]);
  inverse[1][0] = m[0][1];
  inverse[1][1] = m[1][1];
  inverse[1][2] = m[2][1];
  inverse[1][3] = -(m[0][1] * m[0][3] + m[1][1] * m[1][3] + m[2][1] * m[2][3]);
  inverse[2][0] = m[0][2];
  inverse[2][1] = m[1][2];
  inverse[2][2] = m[2][2];
  inverse[2][3] = -(m[0][2] * m[0][3] + m[1][2] * m[1][3] + m[2][2] * m[2][3]);
  inverse[3][0] = 0;
  inverse[3][1] = 0;
  inverse[3][2] = 0;
  inverse[3][3] = 1;
  
  return inverse;
}

/* Returns a 4x4 vector array which reflects the current transform matrix on the top
 * of the stack */
public float[][] getTransformationMatrix() {
  float[][] transform = new float[4][4];
  
  // Caculate four vectors corresponding to the four columns of the transform matrix
  PVector col_4 = getCoordFromMatrix(0, 0, 0);
  PVector col_1 = getCoordFromMatrix(1, 0, 0).sub(col_4);
  PVector col_2 = getCoordFromMatrix(0, 1, 0).sub(col_4);
  PVector col_3 = getCoordFromMatrix(0, 0, 1).sub(col_4);
  
  // Place the values of each vector in the correct cells of the transform  matrix
  transform[0][0] = col_1.x;
  transform[1][0] = col_1.y;
  transform[2][0] = col_1.z;
  transform[3][0] = 0;
  transform[0][1] = col_2.x;
  transform[1][1] = col_2.y;
  transform[2][1] = col_2.z;
  transform[3][1] = 0;
  transform[0][2] = col_3.x;
  transform[1][2] = col_3.y;
  transform[2][2] = col_3.z;
  transform[3][2] = 0;
  transform[0][3] = col_4.x;
  transform[1][3] = col_4.y;
  transform[2][3] = col_4.z;
  transform[3][3] = 1;
  
  return transform;
}

/* This method transforms the given coordinates into a vector
 * in the Processing's native coordinate system. */
public PVector getCoordFromMatrix(float x, float y, float z) {
  PVector vector = new PVector();
  
  vector.x = modelX(x, y, z);
  vector.y = modelY(x, y, z);
  vector.z = modelZ(x, y, z);
  
  return vector;
}

//produce a rotation matrix corresponding to a given set of Euler angles
public float[][] calculateRotationMatrix(PVector wpr){
  float[][] matrix = new float[3][3];
  float phi = wpr.x;
  float theta = wpr.y;
  float psi = wpr.z;
  
  matrix[0][0] = cos(theta)*cos(psi);
  matrix[0][1] = sin(phi)*sin(theta)*cos(psi) - cos(phi)*sin(psi);
  matrix[0][2] = cos(phi)*sin(theta)*cos(psi) + sin(phi)*sin(psi);
  matrix[1][0] = cos(theta)*sin(psi);
  matrix[1][1] = sin(phi)*sin(theta)*sin(psi) + cos(phi)*cos(psi);
  matrix[1][2] = cos(phi)*sin(theta)*sin(psi) - sin(phi)*cos(psi);
  matrix[2][0] = -sin(theta);
  matrix[2][1] = sin(phi)*cos(theta);
  matrix[2][2] = cos(phi)*cos(theta);
  
  return matrix;
}

float[] matrixToQuat(float[][] m){
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

PVector quatToEuler(float[] q){
  PVector wpr = new PVector();
  wpr.x = atan2(2*(q[0]*q[1] + q[2]*q[3]), 1 - 2*(q[1]*q[1] + q[2]*q[2]));
  wpr.y = asin(2*(q[0]*q[2] - q[3]*q[1]));
  wpr.z = atan2(2*(q[0]*q[3] + q[1]*q[2]), 1 - 2*(q[2]*q[2] + q[3]*q[3]));
  
  return wpr;  
}

float[][] quatToMatrix(float[] q){
  float[][] m = new float[3][3];
  
  m[0][0] = 1 - 2*(q[2]*q[2] + q[3]*q[3]);
  m[0][1] = 2*(q[1]*q[2] - q[0]*q[3]);
  m[0][2] = 2*(q[0]*q[2] + q[1]*q[3]);
  m[1][0] = 2*(q[1]*q[2] + q[0]*q[3]);
  m[1][1] = 1 - 2*(q[1]*q[1] + q[3]*q[3]);
  m[1][2] = 2*(q[2]*q[3] - q[0]*q[1]);
  m[2][0] = 2*(q[1]*q[3] - q[0]*q[2]);
  m[2][1] = 2*(q[0]*q[1] + q[2]*q[3]);
  m[2][2] = 1 - 2*(q[1]*q[1] + q[2]*q[2]);
  
  println("matrix: ");
  for(int i = 0; i < 3; i += 1){
    for(int j = 0; j < 3; j += 1){
      print(String.format("  %4.3f", m[i][j]));
    }
    println();
  }
  println();
  
  return m;
}

float[] eulerToQuat(PVector wpr){
  float[] q = new float[4];
  float s1, s2, s3, c1, c2, c3;
  
  s1 = sin(wpr.z/2);
  s2 = sin(wpr.y/2);
  s3 = sin(wpr.x/2);
  c1 = cos(wpr.z/2);
  c2 = cos(wpr.y/2);
  c3 = cos(wpr.x/2);
  
  q[0] = c1*c2*c3 + s1*s2*s3;
  q[1] = s1*c2*c3 - c1*s2*s3;
  q[2] = c1*s2*c3 + s1*c2*s3;
  q[3] = c1*c2*s3 - s1*s2*c3;
  
  return q;
}

//converts a float array to a double array
double[][] floatToDouble(float[][] m, int l, int w){
  double[][] r = new double[l][w];
  
  for(int i = 0; i < l; i += 1){
    for(int j = 0; j < w; j += 1){
      r[i][j] = (double)m[i][j];
    }
  }
  
  return r;
}

//converts a double array to a float array
float[][] doubleToFloat(double[][] m, int l, int w){
  float[][] r = new float[l][w];
  
  for(int i = 0; i < l; i += 1){
    for(int j = 0; j < w; j += 1){
      r[i][j] = (float)m[i][j];
    }
  }
  
  return r;
}

//calculates the change in x, y, and z from p1 to p2
float[] calculateVectorDelta(PVector p1, PVector p2){
  float[] d = {p1.x - p2.x, p1.y - p2.y, p1.z - p2.z};
  return d;
}

//calculates the difference between each corresponding pair of
//elements for two vectors of n elements
float[] calculateVectorDelta(float[] v1, float[] v2, int n){
  float[] d = new float[n];
  for(int i = 0; i < n; i += 1){
    d[i] = v1[i] - v2[i];
  }
  
  return d;
}

//produces a rotation matrix given a rotation 'theta' around
//a given axis
float[][] rotateAxisVector(float theta, PVector axis){
  float[][] m = new float[3][3];
  float s = sin(theta);
  float c = cos(theta);
  float t = 1-c;
  
  if(c > 0.9)
    t = 2*sin(theta/2)*sin(theta/2);
    
  float x = axis.x;
  float y = axis.y;
  float z = axis.z;
    
  m[0][1] = x*x*t+c;
  m[0][2] = x*y*t-z*s;
  m[0][3] = x*z*t+y*s;
  m[1][1] = y*x*t+z*s;
  m[1][2] = y*y*t+c;
  m[1][3] = y*z*t-x*s;
  m[2][1] = z*x*t-y*s;
  m[2][2] = z*y*t+x*s;
  m[2][3] = z*z*t+c;
  
  return m;
}

//calculates the result of a rotation of quaternion 'p'
//about axis 'u' by 'theta' degrees
float[] rotateQuat(float[] p, float theta, PVector u){
  u.normalize();
  println(u);
  float[] q = new float[4];
  q[0] = cos(theta/2);
  q[1] = sin(theta/2)*u.x;
  q[2] = sin(theta/2)*u.y;
  q[3] = sin(theta/2)*u.z;
  
  println("q = " + q[0] + ", " + q[1] + ", " + q[2] + ", " + q[3]);
  println();
  float[] q_star = new float[4];
  q_star[0] = q[0];
  q_star[1] = -q[1];
  q_star[2] = -q[2];
  q_star[3] = -q[3];
  
  float[] p_prime = new float[4];
  p_prime = quaternionMult(q, p);
  p_prime = quaternionMult(p_prime, q_star);
  
  return p_prime;
}

float[] quaternionMult(float[] q1, float[] q2){
  float[] r = new float[4];
  r[0] = q1[0]*q2[0] - q1[1]*q2[1] - q1[2]*q2[2] - q1[3]*q2[3];
  r[1] = q1[0]*q2[1] + q1[1]*q2[0] + q1[2]*q2[3] - q1[3]*q2[2];
  r[2] = q1[0]*q2[2] - q1[1]*q2[3] + q1[2]*q2[0] + q1[3]*q2[1];
  r[3] = q1[0]*q2[3] + q1[1]*q2[2] - q1[2]*q2[1] + q1[3]*q2[0];
  
  return r;
}

/* Displays the contents of a 4x4 matrix in the command line */
public void printHCMatrix(float[][] m) {
  if (m.length != 4 || m[0].length != 4) { return; }
  
  for (int r = 0; r < m.length; ++r) {
    String row = String.format("[ %5.4f %5.4f %5.4f %5.4f ]\n", m[r][0], m[r][1], m[r][2], m[r][3]);
    print(row);
  }
}