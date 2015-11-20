#!/bin/bash
# Script de conversion des vidéos générées par vlc (ipcamsh) en un format compatible avec media node
source=$1
mode=$2
declare -A avconvOptMap=(['mp4']="-pix_fmt yuv420p -vcodec h264 -preset medium -crf 30 -crf_max 31 -r 24 -f mp4")
# à rajouter lorsque la conversion mts -> web-mp4 est configurée ['MTS']=
if [[ -z "${source}"  ]]; then
     echo "L'argument 1 'source' est manquant. C'est le nom du fichier à convertir, sans son extension."
     exit 1
fi
if [[ -z "${mode}" ]]; then
     echo "L'argument 2 'mode' est manquant. Il peut prendre une des valeurs suivantes : ${!avconvOptMap[@]} "
     exit 1
fi
file=${source}.${mode}
if [[ ! -f "${file}" ]]; then
    echo "Le fichier ${file} n'existe pas ou n'est pas visible par l'utilisateur actuel."
    exit 1
fi
echo ${avconvOptMap[$mode]+X}
if [[ "${avconvOptMap[$mode]+X}" -ne "X" ]]; then
    echo "Le mode $mode n'est pas configuré"; exit 1;
fi
echo avconvOptMap[$mode]
echo -i ${file} ${avconvOptMap[$mode]} ${source}.web-mp4
avconv -threads auto -i ${file} ${avconvOptMap[$mode]} ${source}.web-mp4

