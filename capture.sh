#!/usr/bin/env sh
set -xe

#mode=huffyuv-pcm
mode=ffv1-flac
#mode=h264-aac

duration="-t 10"
#duration=

videoDev="-i /dev/video0"
case $(hostname) in
  b550)
    audioDev='-ac 1 -i plughw:CARD=F1000X,DEV=0'
    scratchPath=/run/media/$USER/scratch
    ;;
  c236m)
    # FIXME: call arecord -L to get unambiguous device ID
    audioDev='-i plughw:'
    scratchPath=/scratch
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

