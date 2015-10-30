#!/bin/bash

avconv -i 2015-01-30_11-15_EXP25_CAM_cuisiniere.mpeg -pix_fmt yuv420p -vcodec h264 -preset medium -crf 30 -crf_max 31 -r 12 -f mp4 2015-01-30_11-15_EXP25_CAM_cuisiniere.web.mp4
