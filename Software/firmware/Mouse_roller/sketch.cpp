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
* Fecha: 10/10/2015
* e-mail: pcremades@fcen.uncu.edu.ar
* Plataforma: Arduino.
* Descripción: registra los datos recibidos de un encoder diferencial conectado a los pines 2 y 3 del
* arduino. Envía un caracter por puerto serie indicando la dirección del movimiento cada vez que salta
* la interrupción.
*
* Change Log:
* - 23/10/15: la interrupción por flanco ascendente eliminó el problema de la diferencia de cantidad
* de pulsos registrados en uno y otro sentido.
*
* To do:
*/
#include <Arduino.h>

static int pos=0;

/*ISR de interrupción externa en el PIN 2.
- Cuando salta la interrupción lee el estado de los PINES 2 y 3.
- Si son iguales envía un '1' por puerto serie. Sino envía un '2',
*/
void ISR_roller()
{

  if(digitalRead(3) == digitalRead(2)){
    Serial.print(1);
    Serial.print('\r');
    }
  else{
    Serial.print(2);
    Serial.print('\r');
    }
}

void setup()
{
  pinMode(2, INPUT);
  pinMode(3, INPUT);
  //Habilita interrupción externa en el PIN 2 por flanco ascendente.
  attachInterrupt(INT0, ISR_roller, CHANGE);
  Serial.begin(115200);
}

void loop()
{

}
