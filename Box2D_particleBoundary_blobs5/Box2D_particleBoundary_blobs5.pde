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


// A reference to our box2d world
Box2DProcessing box2d;
// A list for all of our rectangles to track the objects.
ArrayList<Particle> particles;
int cuantas = 40;
PImage fondo;
PVector mov = new PVector();


void setup() {
  size(1280, 720);
  smooth();
  hint(ENABLE_DEPTH_SORT);

  inicializaVideo();

  opencv = new OpenCV(this, width, height);
  
  fondo = loadImage ("fondo.png");
  
  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  // We are setting a custom gravity
  box2d.setGravity(0, -10);

  particles = new ArrayList<Particle>();
  for (int i = 0; i < cuantas; i++) {
    particles.add(new Particle(width/2, height/2, 20));
}
}

void draw() {
  //background(0);
  procesaVideo(); 
  opencv.loadImage(imagenDiferencia); 
  contours = opencv.findContours();
  int usuarios = 0;
  // Para que siempre desaparezcan 
  // los limites son una variable local
  ArrayList<Boundary> boundaries;
  boundaries = new ArrayList<Boundary>();
  for (Contour contour : contours) {
    Rectangle r = contour.getBoundingBox();
    if (r.width > 200 &&  r.height > 200) {
      usuarios ++;      
      if (boundaries.size() < usuarios) {
        // crea uno a uno
        boundaries.add(new Boundary(r.x+r.width/2, r.y + r.height/2, r.width, r.height));
      }
      // y los va a mostrar (display) al final del draw
    }
  }
  println ("Hay " + usuarios + " usuarios y " + boundaries.size() + " cajas limite");
  
  image(fondo, 0, 0);
  dibujaParticulas();

  // We must always step through time!
  box2d.step();

  if (random(1) < 0.2) {
    float sz = random(4, 8);
    particles.add(new Particle(width/2, -20, sz));
  }

  // Display all the particles
  for (Particle b : particles) {
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
  // MUESTRA LOS LIMITES boundaries
  for (Boundary boundary : boundaries) {
    boundary.display();
    boundary.muere();
  }
  //Y desaparecen
  //pero eso no hace que los actualice para las particulas
}


void keyReleased() {
  if (key == 'd' || key == 'D') debug = !debug;
  else if (key == 't' || key == 'T') yaTomoReferencia = false;
}


// Articula movimiento interno de la partícula con un movimiento externo
void dibujaParticulas() {

  mov.x = sin(millis()/1000.0)*900 + width/2;

  if (hayPresencia==false) {
    mov.y = sin(millis()/500.0)*300 + 300;
  } else {
    // int bajar = 400; muy alto ese valor
    int bajar = 4;
    mov.y = mov.y + bajar;
    println("HAY ALGUIEN");
  }

  if (debug) ellipse(mov.x, mov.y, 10, 10);

  for (Particle p : particles) {  
    p.arrive(mov);        // Update the location
    p.update();
    p.display();          // Display the Mover
    p.separate(particles);   //if (mov.x < height/4)
  }
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