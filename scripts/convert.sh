#!/bin/bash
source=$1
destination=$2
avconv -i ${source} -pix_fmt yuv420p -vcodec h264 -preset medium -crf 30 -crf_max 31 -r 24 -f mp4 ${destination}
