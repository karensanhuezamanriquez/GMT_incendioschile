#!/bin/bash
#En este código se filtran los datos dados para la región del bio bio con la opción awk considerando la lat y long de la región y  se imprimen las columnas que cumplen que están dentro de la región. Se cambian las comas por espacios con sed y se ordenan de acuerdo al orden de la columna 6 que corresponde a la fecha. Los cambios realizados al archivo incendios.txt obtenidos de FIRMS descargados de https://www.mttmllr.com/GMT/datos/ArchiveJ1_VIIRS_C2_South_America_VJ114IMGTDL_NRT_2023021_081.txt serán guardados en un nuevo archivo de texto llamado "ordenlat.txt"
more incendios.txt  |  sed 's/,/ /g' | awk '{if ( $1*1 >= (-38.50705) && $1*1 <= (-36.43721) && $2*1 <= (-71.094866) && $2*1 >= (-73.654680)) print $1, $2, $3, $4, $5, $6, $7,  $9, $11}' | sort -k6 -u > ordenlat.txt


