#!/bin/bash

#Con este código se realizara el filtrado de los incendios para la región del bío bío por día. 


#se definen las variables a usar
fecha="fechasincendios.txt"  #fecha de los incendios obtenidas luego de ejecutar generarfecha.sh
datos=ordenlat.txt  #archivo que limita a los incendios observados en la región del bio bio que se obtuvo al ejercutar trabajofinal.sh
sum=000 #contador 


# Se  utiliza un bucle para leer las líneas de la variable fecha 
while IFS= read -r fecha; do
    echo "$fecha"
    sum=$((sum+001))
    echo "$sum"
    i=$(printf "%03d" $sum) #se indica con i la variable del n° día de acuerdo a los valores que va tomando sum
    grep "$fecha" "$datos" | awk '{print $2, $1, $3}' >> dia$i.txt #con grep se busca la fecha en los datos y se guarda en el archivo de texto para cada día respectivamente.
done < "$fecha"

