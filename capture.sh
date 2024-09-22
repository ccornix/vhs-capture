#!/usr/bin/env sh
set -xe

#mode=huffyuv-pcm
mode=ffv1-flac
#mode=h264-aac

#duration="-t 10"
duration=

videoDev="-i /dev/video0"
case $(hostname) in
  b550)
    # Test system using a Genius F1000X webcam
    audioDev='-ac 1 -i plughw:CARD=F1000X,DEV=0'
    scratchPath=/run/media/$USER/scratch
    ;;
  c236m)
    # Capturing system connected to a VCR and MacroSilicon MS210x video grabber
    audioDev='-i plughw:CARD=MS210X,DEV=0'
    scratchPath=/scratch
    ;;
  *)
    echo "invalid hostname" 1>&2
    exit 1
    ;;
esac
case $mode in
  huffyuv-pcm)
    videoCodec='-c:v huffyuv'
    audioCodec='-c:a copy'
    ;;
  ffv1-flac)
    videoCodec='-c:v ffv1'
    videoCodec="$videoCodec -level 3 -g 1 -threads 4 -slicecrc 1 -coder 1 "
    videoCodec="$videoCodec -context 1 -slices 24"
    audioCodec='-c:a flac'
    ;;
  h264-aac)
    videoCodec='-c:v libx264'
    videoCodec="$videoCodec -preset superfast -crf 23 -flags +global_header "
    audioCodec='-c:a aac'
    audioCodec="$audioCodec -b:a 192k"
    ;;
  *)
    echo "invalid mode" 1>&2
    exit 1
    ;;
esac

cd "$scratchPath"
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
ffmpeg \
  -f v4l2 -thread_queue_size 4096 $videoDev \
  -f alsa -thread_queue_size 4096 $audioDev \
  -map 0 -map 1 \
  -vf yadif=1 \
  $duration \
  $videoCodec \
  $audioCodec \
  -f tee "out_${mode}_${timestamp}.mkv|[f=nut:onfail=ignore]pipe:1" |
  ffplay -

