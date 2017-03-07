/* Copyright 2015 Pablo Cremades
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
/**************************************************************************************
* Autor: Pablo Cremades
* Fecha: 04/11/2015
* e-mail: pcremades@fcen.uncu.edu.ar
* Descripción: Sistema de adquisición de datos del péndulo. La aplicación recibe los
* datos del Arduino, por puerto serie. Un '1' indica que el péndulo se ha movido una
* posición en una dirección. '2' indica que se ha movido en la dirección contraria.
* La aplicación utiliza un algoritmo para detectar los máximos y mínimos, y con ello
* calcula el período y la amplitud instantánea. Además, determina el coeficiente de
* amortiguamiento "alpha".
*
* Uso:
* - Presione 'r' para reiniciar la posición del péndulo.
* - Presione 's' para empezar a grabar la posición y determinar Tau y alfa. Debe dejar
*   el péndulo oscilar un par de veces antes de empezar a grabar.
*
* Change Log:
* - 30/09/2016: agrego detección automática del puerto serie.
* - 01/10/2016: mejoré la presentación gráfica.
*/

import processing.serial.*;

Serial port;
String[] serialPorts;
float SAMPLES = 3;
String posString="0";
float ps, ps_old;
float vs=1.0, as, g;
float time=1;
int i=0;
float xplot, yplot;
char inByte;
int pulse1, pulse2;
float amplitud, amplitudIni;
float mx=-1000, mn=1000, lookformax=1, delta=10;
float timePeriod, Period;
int printAlpha = 0;
float Tau, alpha=0, timeAlpha;

float DiamSmall = 2.2;
float DiamBig = 83.0;
float Ratio = DiamBig/DiamSmall;
float Ranuras = 90;   //Raturas y espacios tapados. Raunuras solas son 45
float ThetaPs = 360/Ranuras/Ratio;

int psListMAX = 300;
float[] psList = new float[psListMAX];
int psListptr;

int L=3;

void setup(){
  size(800, 600);
  //Abre el puerto serie.
  serialPorts = Serial.list(); //Get the list of tty interfaces
  for( int i=0; i<serialPorts.length; i++){ //Search for ttyACM*
    if( serialPorts[i].contains("ttyACM") ){  //If found, try to open port.
                println(serialPorts[i]);
      try{
        port = new Serial(this, serialPorts[i], 115200);
        port.bufferUntil('\r');
      }
      catch(Exception e){
      }
    }
  }
  //port = new Serial(this, "/dev/ttyACM0", 115200);
  //port.bufferUntil('\r');  //Guarda sólo hasta que recibe un LineFeed y luego dispara la interrupción.
  frameRate(30);
  ellipseMode(RADIUS);
  xplot = width/3;
  yplot = 20;
}

//ISR de puerto serie
void serialEvent( Serial port ){
    ps_old = ps; //guarda la posición antigua.
    while(port.available() > 0){  //Lee todo lo que haya en el buffer
    inByte = port.readChar();
    if( inByte == '2' ){  //Si es un '1' incrementa la posición
      ps++;
      pulse1++;
    }
    else if(inByte == '1'){  //Si es un '2' decrementa la posición
     ps--;
     pulse2++;
    }
 }
}


void draw(){
  //Actualiza la lista de posiciones
  for(int i=psListMAX-1; i>=1; i--){
   psList[i] = psList[i-1]; 
  }
  psList[0]=ps;
  
  textSize(16);
  float yposCor;
  background(250);  //Limpia el fondo
  yposCor = sqrt((L*100)*(L*100) - (ps)*(ps));  //Calcula la posición en el eje vertical de la masa
  
  //Dibuja el péndulo
  stroke(0, 100, 255);
  strokeWeight(3);
  //line(xplot + ps, yposCor+20, xplot + ps + vs*1000, yposCor+20);
  stroke(0, 100, 255);
  line(xplot, yplot, xplot + ps, yposCor);
  fill(0, 100, 255);
  ellipse(xplot + ps, yposCor, 20, 20);
  
  for(int i=0; i<psListMAX; i++){
   stroke(255,i*100/psListMAX+155,i*255/psListMAX);
   ellipse(xplot + psList[i], L*100+25 + i, 1, 1); 
  }

  //Eventos de teclado
  if( keyPressed ){  //Presinar 'r' para reiniciar.
    if( key == 'r' ){ 
      ps = 0;  //Vuelve la posición a cero.
      mx = -1000;  //Reinicia el algoritmo de búsqueda de máximos y mínimos
      mn = 1000;
      alpha = 0;
      Tau = 0;
    }
    else if (key == 's'){  //Presionar 's' para iniciar búsqueda de 'alpha'
      amplitudIni = amplitud;  //Guarda la amplitud actual como inicial.
      printAlpha = 1;  //Flag para iniciar la búsqueda.
      timeAlpha = millis();  //Guarda el tiempo actual.
    }
  }

//Cálculo de velocidad instantánea
  if( i > 0 ){
    vs = (ps - ps_old)/(millis() - time);
    as = (as + vs)/2.0;
    vs = as;
    time = millis();
    ps_old = ps;
   i = 0;
  }
  i++;
  
//Algoritmo para buscar los máximos y mínimos. (ref. http://www.billauer.co.il/peakdet.html)
  if( ps > mx )
    mx = ps;
  if( ps < mn )
    mn = ps;
  if( lookformax == 1 ){
    if( ps < mx-delta ){  //Encontró un máximo
      amplitud = abs(mx - mn);  //Calcula la amplitud actual
      mn = ps;
      lookformax = 0;
      Period =  (millis() - timePeriod)*2.0;  //Calcula el período.
      timePeriod = millis();  //Guarda el instante en que ocurrió el máximo.
      //println(Period);
    }
  }
  else{
    if( ps > mn+delta ){  //Encontró un mínimo
      amplitud = abs(mx - mn);  //Calcula la amplitud actual.
      mx = ps;
      lookformax = 1;
      Period =  (millis() - timePeriod)*2.0;  //Calcula el período.
      timePeriod = millis();  //Guarda el instante en que ocurrió el mínimo.
    }
  }
  
  //Muestra el período.
  fill(255,50,50);
  textSize(40);
  text("Período [s] = "+round(Period/100)*100/1000.0, width/2, 100);
  //text(Period, 700, 100);
  
  //Verifica si la amplitud ha caído por debajo del 37% de la amplitud inicial.
  if( (amplitud < amplitudIni*0.37) && printAlpha==1  ){
    Tau = (millis() - timeAlpha)/1000;  //Calcula Tau en segundos
    alpha = 1.0/Tau;  //Calcula alpha
    printAlpha = 0;
  }
  
  //Muestra Tau y alpha
  /*text("Angulo inicial = "+int(amplitudIni*ThetaPs)+"º", width/2, 130);
  text("Alpha = "+round(alpha*100)/100.0, width/2, 160);
  text("Tau = "+Tau, width/2, 190);*/
  
 print(millis());
  print("  ");
  println(ps);
}