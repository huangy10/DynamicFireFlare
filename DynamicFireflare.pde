// Woody Huang
// Realtime rendered particle effect simulating fireflare
// Motivated by https://www.openprocessing.org/sketch/422861

// https://github.com/huangy10/DynamicFireFlare
// https://www.jianshu.com/u/927273827560

import java.nio.IntBuffer;
import java.nio.FloatBuffer;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;

import com.jogamp.opengl.GL3;
import com.jogamp.opengl.GL;

final float maxRingSize = 200;
float time= 0;

int partNum;
ArrayList<Integer> partNumbers;

// GLSL related variables
FloatBuffer ringBuffer;
int ringLoc;
int ringVboId;
PJOGL pgl;
GL3 gl;
IntBuffer vbos;
PShader shader;

void setup() {
  size(800, 800, P3D);
  
  shader = loadShader("frag.glsl", "vert.glsl");
  partNumbers = calculateParticleNumbers(maxRingSize);
  partNum = 0;
  for (int x : partNumbers) {
    partNum += x;
  }
  
  // create buffer containing particle data
  ringBuffer = allocateDirectFloatBuffer(partNum * 4);

  // fill ring buffer data
  float angle = 0, radius = 1, offset = 0, idx = 0;
  for (int i : partNumbers) {
    for (int j = 0; j < i; j += 1) {
      idx = j;
      angle = idx / i * TWO_PI;
      ringBuffer.put(angle);
      ringBuffer.put(radius);
      ringBuffer.put(offset);
      ringBuffer.put(idx);
    }
    radius *= 1.005f;
    offset += 0.006f;
  }
  ringBuffer.rewind();

  // configure OpenGL buffers
  pgl = (PJOGL) beginPGL();
  gl = pgl.gl.getGL3();
  vbos = IntBuffer.allocate(1);
  gl.glGenBuffers(1, vbos);
  ringVboId = vbos.get(0);

  // get the location of attribute variables in shader
  shader.bind();
  ringLoc = gl.glGetAttribLocation(shader.glProgram, "ring");
  shader.unbind();
  endPGL();
}

void draw() {

  pgl = (PJOGL) beginPGL();
  gl = pgl.gl.getGL3();
  
  translate(width / 2, height / 2);
  scale(1.5);
  background(0);

  shader.bind();
  shader.set("time", time);
  shader.set("ringTrans", 1f);
  shader.set("randomRotate", 0);

  gl.glEnableVertexAttribArray(ringLoc);
  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, ringVboId);
  gl.glBufferData(
    GL.GL_ARRAY_BUFFER, 
    partNum * 4 * Float.BYTES, 
    ringBuffer, 
    GL.GL_STATIC_DRAW);
  gl.glVertexAttribPointer(ringLoc, 4, GL.GL_FLOAT, false, 4 * Float.BYTES, 0);
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);

  //int x = 0;
  //for (int i : partNumbers) {
  //  gl.glDrawArrays(GL.GL_POINTS, x, i);
  //  x += i;
  //}
  gl.glDrawArrays(GL.GL_POINTS, 0, partNum);

  gl.glBindBuffer(GL.GL_ARRAY_BUFFER, 0);
  gl.glDisableVertexAttribArray(ringLoc);

  shader.unbind();
  endPGL();
  
  time += 0.01;
}

ArrayList<Integer> calculateParticleNumbers(float maxRingSize) {
  ArrayList<Integer> res = new ArrayList();
  float s = 1;
  int nPoints;
  while (s < maxRingSize) {
    nPoints = (int) (PApplet.TWO_PI * s);
    nPoints = PApplet.min(nPoints, 500);
    res.add(nPoints);
    s *= 1.005f;
  }
  return res;
}

FloatBuffer allocateDirectFloatBuffer(int n) {
  return ByteBuffer.allocateDirect(n * Float.BYTES)
    .order(ByteOrder.nativeOrder())
    .asFloatBuffer();
} 