#!/bin/bash
#se genera el archivo de fechas de los incendios con este ejecutable, tal archivo será usado para filtrar los incendios posteriormente y será usado para indica el día de los incendios para cada mapa. 

start_date="2023-01-21" 
end_date="2023-03-23"

fecha_actual="$start_date"

#Se realiza un bucle donde que se ejecutará mientras (while) la fecha actual ($current_date) no sea igual a la fecha de termino  ($end_date).
while [[ "$fecha_actual" != "$end_date" ]]; do
#se añade la fecha actual al archivo de texto
    echo "$fecha_actual" >> fechasincendios.txt
#Actualiza la fecha actual sumándole un día en cada iteración hasta la fecha de corte (end_date). Con date -d se manipulan las  fechas sumandole un día (1 day) considerando el formato año-mes-día (%Y-%m-%d).
    fecha_actual=$(date -d "$fecha_actual + 1 day" +%Y-%m-%d)
done

