import shiffman.box2d.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.collision.shapes.Shape;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;

// A reference to our box2d world
Box2DProcessing box2d;

// A list we'll use to track fixed objects
ArrayList<Boundary> boundaries;
// A list for all of our rectangles
ArrayList<Particle> particles;

void setup() {
  size(640,360);
  smooth();

  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  // We are setting a custom gravity
  box2d.setGravity(0, -10);

  // Create ArrayLists  
  particles = new ArrayList<Particle>();
  boundaries = new ArrayList<Boundary>();

  // Add a bunch of fixed boundaries
  boundaries.add(new Boundary(320,height-155,100,150));
}

void draw() {
  background(255);

  // We must always step through time!
  box2d.step();
  
  if (random(1) < 0.2) {
    float sz = random(4,8);
    particles.add(new Particle(width/2,-20,sz));
  }
  /*
  // Boxes fall from the top every so often
  if (random(1) < 0.2) {
    Particle p = new Particle (width/2,30,30);
    particles.add(p);
  }
  */

  // Display all the boundaries
  for (Boundary wall: boundaries) {
    wall.display();
  }

  // Display all the boxes
  for (Particle b: particles) {
    b.display();
  }

  // Boxes that leave the screen, we delete them
  // (note they have to be deleted from both the box2d world and our list
  for (int i = particles.size()-1; i >= 0; i--) {
    Particle b = particles.get(i);
    if (b.done()) {
      particles.remove(i);
    }
  }
}