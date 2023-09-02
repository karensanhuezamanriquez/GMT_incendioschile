#!/bin/bash


#removimos los archivos generados previamente para optimizar espacio al volver a ejecutar.
rm incendio*.png 
rm incendio*.ps

#SE DEFINEN LA VARIABLES A USAR-------------------------------------------------------------------------------------------

r="-75.65/-71.0/-39.5/-36.1" #región del mapa
j="M12" #tipo de proyección: mercator
jc="-73.15/-35.088/0.9i" #-JClon0/lat0/ancho -> proyección es de 0.9 pulgada
chile="-90/-50/-60/-10" #definimos región de chile
paleta="paleta_mby.cpt" #paleta mby adquirida de http://soliton.vm.bytemark.co.uk/pub/cpt-city/mby/tn/mby.png.index.html


 


#GRILLA-------------------------------------------------------------------------------------------------------------------

# cortamos la topografia obtenida de gmrt maptool (https://gmrt.org/GMRTMapTool/) para nuestra región(r) definida anteriormente, usando grdcut y definiendo la región requerida con -R{r}. Además se guardam con la opción -G como grilla ("topo.grd")
gmt grdcut regionbiobio.grd -Gtopo.grd -R${r}
grid_file=topo.grd #definemos la variable para la grilla 


#OBTENEMOS RESOLUCIÓN GRILLA----------------------------------------------------------------------------------------------
#Aplicamos el comando grdinfo para obtener información de la grilla en la consola: gmt grdinfo topo.grd


#topo.grd: Title: Produced by grdcut
#topo.grd: Command: grdcut regionbiobio.grd -Gtopo.grd -R-75.65/-71.0/-39.5/-36.1
#topo.grd: Remark: 
#topo.grd: Gridline node registration used [Geographic grid]
#topo.grd: Grid file format: nf = GMT netCDF format (32-bit float), CF-1.7
#topo.grd: x_min: -75.6549228553 x_max: -70.9947383593 x_inc: 0.00439640046789 name: longitude n_columns: 1061
#topo.grd: y_min: -39.5028100336 y_max: -36.0962325024 y_inc: 0.00348320810963 name: latitude n_rows: 979
#topo.grd: v_min: -8387.11035156 v_max: 3370.75170898 name: Elevation (m)
#topo.grd: scale_factor: 1 add_offset: 0
#topo.grd: format: netCDF-4 chunk_size: 133,140 shuffle: on deflation_level: 3

#------>resolución de la grilla: x_resolución(x_inc): 0.004; y resolución (y_inc): y_inc: 0.003, que sería una resolución de 36cm aprox. Para los puntos de los incendios usaremos una resolución aproximada menor dado que usando la resolución de 36cm se los incendios se salen del mapa por ello se considerara una resolución inferior pero proporcional igual a 0.036cm.

#ILUMACIÓN-----------------------------------------------------------------------------------------------------------------

# creamos grilla de intensidad para plot de topografia o iluminacion usando grdgradient. Se considera una celda adyacente al calcular el gradiente, lo que contribuye a las sombras realistas en la representación de la topografía con -N usando la opción t1 (-Nt1) y con -A15 indicamos el ángulo de iluminación de 15 grados, es decir, la luz viene de la parte superior izquierda.
gmt grdgradient ${grid_file} -Nt1 -A15 -Gbi.grd

#con grdmath realizamos operaciones matemáticas en la grilla, en este caso multiplicamos cada valor de la grilla por 0.25 para atenuar la intensidad de las sombras. Luego, guardamos la grilla en un archivo .grd ("int.grd")
gmt grdmath 0.25 bi.grd MUL = int.grd

#definimos la variable para la iluminación
grid_brillo=int.grd

#ESTACIONES-----------------------------------------------------------------------------------------------------------------

#Se adquieren los datos de dirección y velocidad de 5 estaciones meteorologicas de agrometeorologia (https://agrometeorologia.cl/VV_MES#).

#En direc_vient_agro.csv y veloc_viento_agro.csv se encuentran tanto la dirección y velocidad de los vientos  de las 5 estaciones desde el 21 de enero al 22 de marzo. 

#Dado que los archivos .csv adqueridos de la pág cuenta con texto innecesario se deben trabajar los datos. Para ello,  usamos los comandos awk para considerar las filas superiores a 6 e inferiores a 68, e imprimir las columnas de las 2 a 6, dado que cada columna indica una estación. Además, con sed quitamos las comillas y cambiamos las comas por espacios. Luego los cambios son guardados en nuevos archivos de texto.

#more direc_vient_agro.csv | awk '68>NR && NR>6 {print $0}'| sed 's/"//g' | sed 's/,/ /g' | awk '{print $2, $3, $4, $5, $6}' > direc_vient.txt 

#Para el procesamiento de datos de velocidad se realiza la misma secuencia de comandos usados para filtrar las direcciones de las estaciones pero añadiendo un comando extra para disminuir la escala de la velocidad, dado que no se desea vectores de tamaño tan grande como para no verse en el mapa que es lo que ocurre al usar las velocidades adquiridas. Por ello, se usa el comando awk con el cual se iterará a través de las cinco columnas obtenidas utilizando un ciclo for que multiplica las velocidades por 0.1.

#more veloc_viento_agro.csv | awk '68>NR && NR>6 {print $0}'| sed 's/"//g' | sed 's/,/ /g' |  awk '{print $2, $3, $4, $5, $6}' |  awk '{ for (i=1; i<=5; i++) $i *= 0.1; print }'   > veloc_vient.txt 


#-------------------SE UTILIZA CICLO FOR ITERAR LOS MAPAS DE  INCENDIOS DE ACUERDO A SU FECHA ---------------------------------


for i in {001..061} 
do

#MARCO DEL MAPA--------------------------------------------------------------------------------------------

#Se crea el marco del mapa con psbasemap para nuestra región -R{r} con la proyección mercator -J{j}. Con -B indicamos las característica de las etiquetas de los ejes, para este caso se desea esten etiquetados  los ejes norte, sur, este y oeste (SEWN), y que se tengan etiquetas cada 1 grado y las subdivisiones menores cada 0.5 grados. También, se desea que el mapa este en centro de la pág, tal que X e Y que indican el desplazamiento horizontal y vertical respectivamente, se le añadirá c (center) . 

#Además, indicamos con -P que es un elemento postscript que representa  el mapa en formato .ps, que  mantenga abierto el script con -K para añadir más elementos al mapa y que  las características del marco sean guardadas  en cada mapa de los incendios (> incendio$i.ps)

gmt psbasemap -Ba1f0.5SEWN -J${j} -R${r} -Xc -Yc -P -K > incendio$i.ps

#IMAGEN DE LA GRILLA----------------------------------------------------------------------------------------------------------

#Incluimos la grilla topo.grd, añadimos la paleta mby en  la opción -C  e iluminamos la topografía añidiendo el archivo creando anteriormente grid_I_file con la opción -I. Indicamos superposición de elementos con  -O y mantenemos abierto el código a modificaciones con -K. Con >> ${name} indicamos que se añada la línea de código a la imagen .ps generada anteriormente (incendio.ps)

gmt grdimage topo.grd  -I${grid_brillo} -C${paleta} -R -J -B  -O -K >> incendio$i.ps

#LÍNEA DE COSTA --------------------------------------------------------------------------------------------------------------

#Graficamos la línea de costa con pscoast, volvemos a definir el tipo de proyección mercator con -J, también se definen nuevamente los eje de la costas que cuentan con 5 etiquetas principales y dos subsidiciones con -Bah5g2f1. Definimos una resolución alta con -D usando la opción h (-Dh). Con -W0.3,0 se define que la línea de costa tendrá un ancho de 0.3 unidades y un estilo sólido (0). Indicamos una azul oscuro en formato RGB con un intervalo de  4 unidades y 0.1 unidades de latitud usando la opción -I (-I4/0.1,39/64/139).Se definen las fronteras nacionales con un grosor de una unidad con la opción -N1.

gmt pscoast -R${r} -J${j} -Ba5g2f1 -Dh -W0.3,0 -I4/0.1,39/64/139 -N1 -O -K  -P >> incendio$i.ps

#FOSA--------------------------------------------------------------------------------------------------

#Se utiliza psxy para insertar figuras en el gráfico. Para este caso se utilizara para indicar la fosa considerando los datos del archivo trench-chile usando la opción -S para trazar los simbolos. Se trazara una flecha (f)  tamaño de 0.5 pulgadas de ancho y 0.1 pulgadas de alto. Se agregara una cabeza de flecha (+r). Se colocará una etiqueta cerca del símbolo (+t) y con +o1 se indicará que desea colocar la etiqueta a una distancia de 1 pulgada del símbolo.  

#Además, se añadirán guadrillas añadiendo la opción B, los cambios se sobrepondrán y guardaran en incendio.ps y se mantendrá abierto el código (-K).

gmt psxy trench-chile -R -J -W0.2p -Sf0.5i/0.1i+r+t+o1  -Gwhite  -B -O -K  >> incendio$i.ps

#MAPA PEQUEÑO DE REFERENCIA----------------------------------------------------------------------------

#usamos pscoast para trazar la costa del mapa, definiendo la región del mapa usando los límites geográficos de Chile y con la proyección ya definida anteriormente (jc). 

#Se añade las cuadricula al mapa con intervalor de 6 grados.  Con Dh indicamos una resolución alta. 
#Se considera un desplazamiento vertical y horizontal respecto a la pág (-X+0.2 -Y8). Con A8 se indica que  GMT utilice su propio criterio para determinar cómo se anotarán los ejes basándose en el sistema de coordenadas y la proyección establecida (jc).

#También, se considera un grosor de 0.25 puntos (-W0.25p)  y un color del fondo tipo anaranjado con -G255/187/86. Y se guardan los cambios en incendio.ps y se mantiene abierto el código (-K)
gmt pscoast -R${chile} -JC${jc} -Bg6 -Dh -X+0.2 -Y8 -A8 -W0.25p -G255/187/86 -O -K >> incendio$i.ps

#Se inserta cuadrado de la región de estudio:

#Imprimiendo la región ${r} de estudio, haciendo con sed que se reemplacen todos los caracteres(\) impresos por un espacio. Con awk se procesan las columnas para que se genere un rectangulo en el mapa. Luego, con gmt psxy se trazan las coordenadas del poligono consideran la región de Chile un groso de línea de 0.9 puntos de color blanco (Gwhite), se cierra el rectangulo con -A, se guardan los cambios y se mantiene abierto el código. 
echo ${r} | sed 's/\// /g' | awk '{printf"%s %s\n %s %s\n %s %s\n %s %s\n %s %s\n", $1, $3, $2, $3, $2, $4, $1, $4, $1, $3}'| gmt psxy -R${chile} -JC${jc} -Wwhite  -A -O -K >>  incendio$i.ps

#PUNTOS NARANJAS PARA LOS INCENDIOS----------------------------------------------------------------------------------

#Se grafican los puntos usando el comando psxy que leera los archivos de incendios  donde se tiene las latitudes y longitudes y el brillo de cada incendio gracias al ciclo for definido (dia$i.txt) y los graficará considerando la región del mapa (r) y su proyección mercator (j).  Y contrarestantando el desplazamiento para el mapa pequeño se considera un desplazamiento negativo (-X-0.2  -Y-8)

#Con -Ss0.4c indicamos la forma y el tamaño de 0.04 cm y de acuerdo a su brillo captado en grados kelvin se le designará un color dado por la paleta (-Cpaleta_brillo.cpt). Se sobreponen y se guardan los cambios en incendio.ps 

gmt psxy dia$i.txt -J${j} -R${r} -Ss0.036c  -Cpaleta_brillo.cpt -X-0.2  -Y-8 -O -K >> incendio$i.ps

#ESCALA DE PALETA DE BRILLO

#Con psscale se añade la escala de la  paleta de colores generada de acuerdo al brillo de los incendios (paleta_brillo.cpt).  Con -Ba50f10/a50f10:"Brillo (K)" se definen las etiquetas en los ejes de la escala de colores con "Brillo (K)" siendo la etiqueta . Se indica etiquetas cada 50 unidades con intervalos de 10 (a50f10).
#Se usa verbose (-V) para que en la terminal salgan mensajes detallados. Se guardan los cambios en incendios y se mantiene abierto el código.
gmt psscale -D14c/2.5c/5c/0.5c -Cpaleta_brillo.cpt -Ba50f10/a50f10:"Brillo (K)": -V -O -K >> incendio$i.ps


#LOCALIDADES---------------------------------------------------------------------------------------------------------

#::Comunas::

#para definir las comunas se debe ingresar texto en el mapa, para ello se utiliza pstext, donde se ingresa la latitud y longitud donde se quiere que empiece el texto, en este caso corresponde a las latitudes y longitudes de cada localidad, considerando la región en el mapa (-R{r}), la proyección mercator (J${j}), que el archivo de salida es un postscript (-P), añadimos mensajes de salida adicionales con verbose (-V). 
#Se define una fuente para el texto Times-Bold, de tamaño de 10puntos (F+f10p) de color negros (black) con alineación hacia la izquierda (jLM) y con el color de etiqueta blanco -Gwhite.

#Nuevamente indicamos que se superpone y se cierra la línea de script pero se mantendrá abierto para añidir elemento. Guadarno los elementos en incendio.ps
echo -73.04977  -36.82699 "Concepción" | gmt pstext -R${r}  -J${j} -P -V -F+f10p,Times-Bold,black+jLM -Gwhite -O -K >> incendio$i.ps
echo -72.35366 -37.46973 "Los Ángeles" | gmt pstext  -R${r}  -J${j} -P -V -F+f10p,Times-Bold,black+jLM -Gwhite -O -K >> incendio$i.ps
echo -73.31752 -37.2463 "Arauco" | gmt pstext  -R${r} -J${j} -P -V -F+f10p,Times-Bold,black+jLM -Gwhite -O -K >> incendio$i.ps
echo -72.35233 -37.78622  "Santa Ana"| gmt pstext  -R${r} -J${j} -P -V -F+f10p,Times-Bold,black+jLM -Gwhite -O -K >> incendio$i.ps
echo -73.65356 -37.60825 "Lebu" | gmt pstext -R${r} -J${j}  -P -V -F+f10p,Times-Bold,black+jLM -Gwhite -O -K >> incendio$i.ps
echo -71.67642 -37.3313 "Antuco" | gmt pstext -R${r} -J${j}  -P -V -F+f10p,Times-Bold,black+jLM -Gwhite -O -K >> incendio$i.ps

#::puntos azul::

#se define un punto azul para caracterizar la ubicación de las comunas para ello utilizamos gmt psxy que se utiliza para ingresar símbolos al mapa, consideramos la latitud  y longitud deltexto de donde se encuentra la comuna, corremos 0.1 grados la longitud en comparación del texto para que sea visible y la latitud se mantiene invariante; para ello se considera la región (-R${r}) y la proyección. 

# Se definien los puntos rojos con -Gred con las características de 0.2 cm de tamaño con forma de círculo (C) (Sc0.2C) con bordes negros(0) de 0.5 puntos de ancho W0.5p,0. Se sobreponen los cambios y se mantiene abierto el código.

echo "-73.14977 -36.82699" | gmt psxy -R${r} -J${j} -Sc0.2C -W0.5p,0 -Gblue  -O -K>> incendio$i.ps
echo "-72.45366 -37.46973" | gmt psxy -R${r} -J${j} -Sc0.2C -W0.5p,0 -Gblue  -O -K>> incendio$i.ps
echo "-73.41752 -37.2463" | gmt psxy -R${r} -J${j} -Sc0.2C -W0.5p,0 -Gblue  -O -K>> incendio$i.ps
echo "-72.45233 -37.78622" | gmt psxy -R${r} -J${j} -Sc0.2C -W0.5p,0 -Gblue -O -K>> incendio$i.ps
echo "-73.75356 -37.60825" | gmt psxy -R${r} -J${j} -Sc0.2C -W0.5p,0 -Gblue  -O -K>> incendio$i.ps
echo "-71.77642 -37.3313" | gmt psxy -R${r} -J${j} -Sc0.2C -W0.5p,0 -Gblue -O -K>> incendio$i.ps

#LEYENDA---------------------------------------------------------------------------------------------------

#Volvimos a añadir texto al mapa con pstext  para la región del mapa r con proyección mercator j,  al igual que en las etiquetas para las localidades también se considera un tamaño de la etiqueta de 10 puntos +f10p con un fondo blanco Gwhite, con un color de letra negro (black), con alineación hacia la izquierda (jLM) pero con letra arial.  Luego con psxy se añade el símbolo correspondiente a cada elemento de la leyenda.
echo -75.5 -38.4 "Leyenda:" |  gmt pstext -R${r} -J${j}  -F+f10p,Helvetica,black+jLM -Gwhite -O -K >> incendio$i.ps

echo -75.5 -38.7 "Incendios" |  gmt pstext -R${r} -J${j}  -F+f10p,Helvetica,black+jLM -Gwhite -O -K >> incendio$i.ps
echo "-75.55 -38.7"| gmt psxy -J${j} -R${r} -Ss0.2c -W0.005p,0 -G255/175/0 -O -K >> incendio$i.ps

echo -75.5 -38.6 "Localidades" |  gmt pstext -R${r} -J${j}  -F+f10p,Helvetica,black+jLM -Gwhite -O -K >> incendio$i.ps
echo "-75.55 -38.6" | gmt psxy -R${r} -J${j} -Sc0.2C -W0.5p,0 -Gblue  -O -K>> incendio$i.ps

echo -75.5 -38.8 "Dirección viento" |  gmt pstext -R${r} -J${j}  -F+f10p,Helvetica,black+jLM -Gwhite -O -K >> incendio$i.ps
echo -75.5 -38.9 "con v en km/h" |  gmt pstext -R${r} -J${j}  -F+f10p,Arial,black+jLM -Gwhite -O -K >> incendio$i.ps
echo "-75.55 -38.9 0 0.5" | gmt psxy -J${j} -R${r} -SV0.05c/0.3c/0.075c -G0 -Wwhite -V -O -K >> incendio$i.ps



#INDICADOR DE LA FECHA DE LOS INCENDIOS--------------------------------------------------------------------------------

#se define la variable fechas para cada fecha guardada en el archivo fecha.txt obtenido luego de ejecutar generarfecha.sh. Con awk se intera cada línea del archivo fecha.txt
fechas=$(awk -v n=$i 'NR==n' fechasincendios.txt)

echo $fechas

#Se coloca las fechas de los incendios en la parte inferior del mapa, y con pstext se genera el texto con letra helvetica-bold de color rojo la fecha yyyy/mm/dd y negro el indicador de la fecha. Nuevamente se vuelve a considerar un tamaño de la etiqueta de 10 puntos +f10p con un fondo blanco Gwhite.  Se pide que se muestren los mensajes en detalle en pantalla con verbose (-V). Y se sobreponen los cambios y se mantiene abierto el código. 
echo -73.5 -39.2 "$fechas" | gmt pstext  -R${r}  -J${j} -F+f10p,Helvetica-Bold,red+jLM  -Gwhite -V -O -K >> incendio$i.ps
echo -74 -39.2 "Fecha:"| gmt pstext  -R${r}  -J${j} -F+f10p,Helvetica-Bold,black+jLM  -Gwhite  -V -O -K >> incendio$i.ps

#VECTORES DE DIRECCIÓN DEL VIENTO DEPENDIENDO DE LA ESTACIÓN-----------------------------------------------------------

#primera estación: Aeródromo María Dolores (log: -72.42; lat: -37.4)
#definimos variables de dirección y velocidad para cada estación. Donde se indica en awk que  i  (cada día) irá iterando fila a fila de su respectiva columna del archivo de texto. Luego, se graficaran los vectores consideran la ubicación de cada estaciones (buscadas en google) teniendo el cuenta que para graficar un vector se necesita "lon lat azimut largo", que para este caso el azimut estará dado por la dirección y el largo por la velocidad reducida 0.1. Con psxy se graficaran los simbolos de vector, estimulando sus característica de vector añadiendo una V a -S (-SV) y se indicará un tamaño de la cabeza de 0.05 cm, con la recta del vector  de un largo de 0.3 cm y ancho de 0.15cm. Se considerara un color de relleno negro (-G0) y  estableciendo un estilo de la recta del vector  con ancho de línea de 1 punto con un estilo sólido de color negro (-W1,0/0/0). Se pide que se vean los mensajes detallados en la terminal con verbose (-v). Los cambios se sobrepondran y se guardarán en incendio.ps, y se mantendrá abierto el código.


#PRIMERA ESTACIÓN: AERÓDROMO MARÍA DOLORES 
direc=$(awk -v n=$i 'NR==n {print $1}' direc_vient.txt)
veloc=$(awk -v n=$i 'NR==n {print $1}' veloc_vient.txt)
echo "-72.42  -37.4 $direc  $veloc " | gmt psxy -J${j} -R${r} -SV0.05c/0.3c/0.15c -G0 -W1,0/0/0 -V-O -K >> incendio$i.ps

#SEGUNDA ESTACIÓN: CARRIEL SUR, CONCEPCIÓN
direc5=$(awk -v n=$i 'NR==n {print $5}' direc_vient.txt)
veloc5=$(awk -v n=$i 'NR==n {print $5}' veloc_vient.txt)
echo "-73.06  -36.78 $direc5 $veloc5" | gmt psxy -J${j} -R${r} -SV0.05c/0.3c/0.15c -G0 -W1,0/0/0 -V -O -K >> incendio$i.ps

#TERCERA ESTACIÓN: GTT PELECO, CAÑETE
direc2=$(awk -v n=$i 'NR==n {print $2}' direc_vient.txt)
veloc2=$(awk -v n=$i 'NR==n {print $2}' veloc_vient.txt)
echo "-73.41  -37.89 $direc2 $veloc2" | gmt psxy -J${j} -R${r} -SV0.05c/0.3c/0.15c -G0 -W1,0/0/0 -V -O -K >> incendio$i.ps

#CUARTA ESTACIÓN: SANTA LUCÍA, FLORIDA
direc3=$(awk -v n=$i 'NR==n {print $3}' direc_vient.txt)
veloc3=$(awk -v n=$i 'NR==n {print $3}' veloc_vient.txt)
echo "-72.70  -36.69 $direc3 $veloc3" | gmt psxy -J${j} -R${r} -SV0.05c/0.3c/0.15c -G0 -W1,0/0/0 -V -O -K >> incendio$i.ps

#QUINTA ESTACIÓN, HÚSARES, ANGOL 
direc4=$(awk -v n=$i 'NR==n {print $4}' direc_vient.txt)
veloc4=$(awk -v n=$i 'NR==n {print $4}' veloc_vient.txt)
echo "-72.68  -37.79 $direc4 $veloc4" | gmt psxy -J${j} -R${r} -SV0.05c/0.3c/0.15c -G0 -W1,0/0/0 -V -O  >> incendio$i.ps


#convertir a png
gmt psconvert incendio$i.ps -A -Tg -V
done

#se genera un gif con las imagenes png generadas. Se añade el comando -delay 10 para establecer el tiempo en centésimas de segundo para la siguiente imagen. Usamos 10 dado que si usamos un valor de 20 el gif se ve más cortado. 
#loop 0 indica reproduccie el blucle infinitamente.
# definimos el patrón de archivos que queremos convertir a gif -> incendio*.png  

convert -delay 10 -loop 0 incendio*.png animacion_inc.gif


