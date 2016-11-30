// A rectangular box
class Particle {
  
  PImage img;
  PVector location;
  PVector velocity;
  PVector acceleration;
  float maxforce;
  float maxspeed;
  
  // We need to keep track of a Body and a width and height
  Body body;
  float r;

  // Constructor
  Particle(float x, float y, float r_) {
    
    img = loadImage ("pana2.png");
    acceleration = new PVector(0,0);
    location = new PVector(random(width),random(height));
    velocity = new PVector(0,0);
    maxspeed = random(10, 30);
    maxforce = random(0.5,1.5);
    
    r = r_;
    
    // Add the box to the box2d world
     makeBody(x, y, r);
     body.setUserData(this);
  }

  // This function removes the particle from the box2d world
  void killBody() {
    box2d.destroyBody(body);
  }

   // Is the particle ready for deletion?
  boolean done() {
    // Let's find the screen position of the particle
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Is it off the bottom of the screen?
    if (pos.y > height+r*2) {
      killBody();
      return true;
    }
    return false;
  }
  
    // This function adds the rectangle to the box2d world
  void makeBody(float x, float y, float r) {

 // Define a body
    BodyDef bd = new BodyDef();
    // Set its position
    bd.position = box2d.coordPixelsToWorld(x, y);
    bd.type = BodyType.DYNAMIC;
    body = box2d.createBody(bd);

    // Make the body's shape a circle
    CircleShape cs = new CircleShape();
    cs.m_radius = box2d.scalarPixelsToWorld(r);

    FixtureDef fd = new FixtureDef();
    fd.shape = cs;
    // Parameters that affect physics
    fd.density = 1;
    fd.friction = 0.01;
    fd.restitution = 0.3;

    // Attach fixture to body
    body.createFixture(fd);

    body.setAngularVelocity(random(-10, 10));
  }
  
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    location.add(velocity);
    acceleration.mult(0);  
  }
  
  
   void applyForce(PVector force) {
     acceleration.add(force);
 }
  
  void arrive(PVector target) {
    PVector desired = PVector.sub(target,location);  // desired = vector desde la posición al target
    float d = desired.mag();
      // Si la distancia entre el objeto y el target es menor a 100 píxeles...
    if (d < 100) {
      float m = map(d,0,100,0,maxspeed);
      desired.setMag(m);
    } else {
      // Proceder al máximo de velocidad (maxspeed)
      desired.setMag(maxspeed);
    }

    // Fuerza de dirección (steering) = velocidad deseada (desired) - velocidad actual (velocity)
    PVector steer = PVector.sub(desired,velocity);
    steer.limit(maxforce);  // Limitar a la máxima fuerza de dirección
    applyForce(steer);
   }
  
  
  void separate (ArrayList<Particle> particles) {
    float desiredseparation = random (200, 500); 
    PVector sum = new PVector();
    int count = 0;
    // buscar todos los elementos en la lista "movers" y traer cada elemento,
    // uno atrás de otro, a la variable(objeto) "other"
    for (Particle other : particles) {
      float d = PVector.dist(location, other.location);
      if ((d > 0) && (d < desiredseparation)) {
        PVector diff = PVector.sub(location, other.location);
        diff.normalize();
        // Mientras más cerca esta el vehículo de otro más se tiene que alejar 
        // (mayor la magnitud del PVector que los aleja), mientras nmás lejos, menos.
        // Dividimos por la distancia para calcular adecuadamente
        diff.div(d); 
        sum.add(diff);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      applyForce(steer);
    }
  }
  
  // Drawing the box
  void display() {
     // We look at each body and get its screen position
    Vec2 pos = box2d.getBodyPixelCoord(body);
    // Get its angle of rotation
    //float a = body.getAngle();
   // pushMatrix();
    //translate(pos.x, pos.y);
    //rotate(a);
    //fill(255,0,0);
    //stroke(0);
    //strokeWeight(1);
    //ellipse(0, 0, r, r);
    //image(img,pos.x,pos.y,100,100);
    image(img,location.x,location.y,100,100);
   // popMatrix();
  }


}