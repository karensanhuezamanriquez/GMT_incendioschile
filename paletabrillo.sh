#!/bin/bash
#Este código se utiliza para generar la paleta de colores de acuerdo al brillo en grados kelvin que se encuentra en la columna 3 del archivo ordenlat.txt


# Se definen las variables de archivo de datos y columna de brillo
data_file="ordenlat.txt"
brightness_column=3


# Obtener los valores mínimos y máximos de brillo en tus datos:

#Se utiliza el comando awk para extraer los valores de brillo de la columna de brillo ($brightness_column) en el archivo de datos ($data_file). Luego, eso valores se ordenan númericamente de forma ascendente con el comando sort -g. Con  head -n 1 se obtiene el valor mínimo y tail -n 1 se obtiene el valor máximo. Los resultados se almacenan en las variables min_val y max_val.
min_val=$(awk -v col=$brightness_column 'NR > 1 {print $col}' $data_file | sort -g | head -n 1)
max_val=$(awk -v col=$brightness_column 'NR > 1 {print $col}' $data_file | sort -g | tail -n 1)

# Se genera la paleta con makecpt, con transciciones de amarillo a naranja y de naranja a rojo (-Cyellow,orange,red) de acuerdo a los valores min y máximos de los incendios (-T$min_val/$max_val). Luego, la paleta de brillo se guardara en "paleta_brillo.cpt"
gmt makecpt -Cyellow,orange,red -T$min_val/$max_val > paleta_brillo.cpt





