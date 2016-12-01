import shiffman.box2d.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.joints.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.collision.shapes.Shape;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.contacts.*;
import processing.video.*;
import gab.opencv.*;
import java.awt.*;

OpenCV opencv;
ArrayList<Contour> contours;

PImage fondo;

//CAPTURA VIDEO//
Capture video;
int camPixels;
PImage antesPixels, imagenDiferencia;
boolean yaTomoReferencia;
//CAPTURA VIDEO//

//SENSADO//
int limiteDiferencia = 30;
int limitePresencia = 15000000;
boolean hayPresencia = false;
boolean debug = false;
//SENSADO//

//Box2D//
// A reference to our box2d world
Box2DProcessing box2d;
// Just a single box this time
// Box box;
// An ArrayList of particles that will fall on the surface
ArrayList<Particle> particles;
// The Spring that will attach to the box from the mouse
Spring spring;
// Perlin noise values
float xoff = 0;
float yoff = 1000;
int cuantas = 20;
//Box2D//


void setup() {
  size(1280,720);
  smooth();
  hint(ENABLE_DEPTH_SORT);
  //fondo = loadImage ("fondo.png");
  
  inicializaVideo();

  opencv = new OpenCV(this, width, height);
  
  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  // We are setting a custom gravity
  box2d.setGravity(0, -10);

  // Add a listener to listen for collisions!
 // box2d.world.setContactListener(new CustomListener());

  // Make the box
  // box = new Box(width/2,height/2,width/4,height/4);

  // Make the spring (it doesn't really get initialized until the mouse is clicked)
  // spring = new Spring();
  // spring.bind(width/2,height/2,box);

  // Create the empty list
  particles = new ArrayList<Particle>();
  for (int i = 0; i < cuantas; i++) {
    particles.add(new Particle(random(width/2), random(height/2), 10));
  }


}

void draw() {
  background(0);
  procesaVideo(); 
  opencv.loadImage(imagenDiferencia); 
  contours = opencv.findContours();
  int usuarios = 0;
  // Para que siempre desaparezcan 
  // los limites son una variable local
  ArrayList<Box> boundaries;
  boundaries = new ArrayList<Box>();
  for (Contour contour : contours) {
    Rectangle r = contour.getBoundingBox();
    if (r.width > 200 &&  r.height > 200) {
      usuarios ++;      
      if (boundaries.size() < usuarios) {
        // crea uno a uno
        boundaries.add(new Box(r.x+r.width/2, r.y + r.height/2, r.width, r.height));
      }
      // y los va a mostrar (display) al final del draw
    }
  }
  println ("Hay " + usuarios + " usuarios y " + boundaries.size() + " cajas limite");

  //dibujaParticulas();
  
  if (random(1) < 0.2) {
    float sz = random(4,8);
    //particles.add(new Particle(width/2,-20,sz));
  }

  // We must always step through time!
  box2d.step();
  /*
  // Make an x,y coordinate out of perlin noise
  float x = noise(xoff)*width;
  float y = noise(yoff)*height;
  xoff += 0.01;
  yoff += 0.01;
  */

  // This is tempting but will not work!
  // box.body.setXForm(box2d.screenToWorld(x,y),0);
/*
  // Instead update the spring which pulls the mouse along
  if (mousePressed) {
    spring.update(mouseX,mouseY);
  } else {
    spring.update(x,y);
  }
  */
   if (mousePressed) {
    for (Particle p: particles) {
     p.attract(sin(millis()/1000.0)*900 + width/2,sin(millis()/500.0)*300 + 300);
     box2d.setGravity(0, 0);
    }
  }
  //box.body.setAngularVelocity(0);

  // Look at all particles
  // Boxes that leave the screen, we delete them
  // (note they have to be deleted from both the box2d world and our list
  for (int i = particles.size()-1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.display();
    // Particles that leave the screen, we delete them
    // (note they have to be deleted from both the box2d world and our list
    if (p.done()) {
      particles.remove(i);
    }
  }
  
   // MUESTRA LOS LIMITES boundaries
  for (Box boundary : boundaries) {
    boundary.display();
    boundary.killBody();
  }
  //Y desaparecen
  //pero eso no hace que los actualice para las particulas
  
  
  // Draw the box
  // box.display();

  // Draw the spring
  // spring.display();
}

void keyReleased() {
  if (key == 'd' || key == 'D') debug = !debug;
  else if (key == 't' || key == 'T') yaTomoReferencia = false;
}

void tomarReferencia() {
  antesPixels.loadPixels();
  for (int i = 0; i < camPixels; i++) {
    antesPixels.pixels[i] = video.pixels[i];
  }
  antesPixels.updatePixels();
}

void procesaVideo() {
  if (video.available()) {
    // Leer nuevo frame de video
    video.read(); 
    // Hacer disponibles los pixels del video
    video.loadPixels();
    if (!yaTomoReferencia) {
      tomarReferencia();
      yaTomoReferencia = true;
    }
    sustraccionFondo();
  }
  // Dibuja el resultado
  if (debug) { // si se necesita verificar el contenido de las imagenes
    image(imagenDiferencia, 0, 0, width/2, height/2);
    image(antesPixels, width/2, 0, width/2, height/2);
    image(video, width/2, height/2, width/2, height/2);
  } else { // de lo contrario imagen de fondo camara
    image(imagenDiferencia, 0, 0);
  }
}

void sustraccionFondo() {
  int presenceSum = 0;
  // Diferencia entre el frame actual y el fondo almacenado
  // Límite para comparar si el cambio entre las dos imágenes es mayor a...
  imagenDiferencia.loadPixels();
  // Para cada pixel de video de la cámara, tomar el color actual y el anterior de ese pixel
  for (int i = 0; i < camPixels; i++) { 
    color currentColor = video.pixels[i];
    color backgroundColor = antesPixels.pixels[i];
    // Extraer los colores de los píxeles del frame actual
    int currentR = (currentColor >> 16) & 0xFF;
    int currentG = (currentColor >> 8) & 0xFF;
    int currentB = currentColor & 0xFF;
    // Extraer los colores de los píxeles del fondo
    int backgroundR = (backgroundColor >> 16) & 0xFF;
    int backgroundG = (backgroundColor >> 8) & 0xFF;
    int backgroundB = backgroundColor & 0xFF;
    // Computar la diferencia entre los colores
    int diffR = abs(currentR - backgroundR);
    int diffG = abs(currentG - backgroundG);
    int diffB = abs(currentB - backgroundB);
    float promedio = (diffR + diffG + diffB)/3.0;
    // si el pixel es diferente dibuja el mismo pixel
    if (promedio > limiteDiferencia) imagenDiferencia.pixels[i] = currentColor;
    // de lo contrario negro
    else imagenDiferencia.pixels[i] = 0;
    // Sumar las diferencias a la cuenta
    presenceSum += promedio;
  }
  imagenDiferencia.updatePixels();
  //println(presenceSum);
  if (presenceSum > limitePresencia) hayPresencia = true;
  else hayPresencia = false;
}

void inicializaVideo() {
  String[] cameras = Capture.list();
  printArray(cameras);
  // Empezar la captura
  video = new Capture(this, width, height);
  //video = new Capture(this, 1920, 1080, cameras[57]);
  video.start();
  // Almacenar píxeles de la cámara en variable camPixels
  camPixels = video.width * video.height;
  // Almacenar la imagen el fondo que servirá de referencia en una PImage
  antesPixels = new PImage (video.width, video.height);
  imagenDiferencia = new PImage (video.width, video.height);
  yaTomoReferencia = false;
}