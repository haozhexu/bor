#!/bin/sh

ARGS_RESIZE=
ARGS_QUALITY=
ARGS_BORDER=
ARGS_BORDERCOLOR=
ARGS_ANNOTATION_TEXT=
ARGS_EXIF_OPTIONS=
ARGS_FONT_SIZE="medium"

DEBUG_ENABLED=""

usage() {
    echo "Usage:"
    echo "`basename $0`  [-b border options] [-d](enable debug output) [-e EXIF options] [-f (small|medium|large)] [-q quality] [-r resize options] input_file [output_file]"
}

decho() {
    if [ ! -z $DEBUG_ENABLED ]; then
        echo "[DEBUG] ${1}"
    fi
}

apply_exif_annotation()
{
    if [ $# -eq 2 ]; then
        decho "Apply exif annotation: $1 for $2"
        declare `convert -ping "$2" -format "cameramodel=%[EXIF:model]\n focallength35=%[EXIF:FocalLengthIn35mmFilm]\n fnumber=%[EXIF:FNumber]\n exptime=%[EXIF:ExposureTime]\n isospeed=%[EXIF:ISOSpeedRatings]\n" info:`
        fnumber1=`echo $fnumber | cut -d/ -f1`
        fnumber2=`echo $fnumber | cut -d/ -f2`
        fnumber=`echo "scale=1; $fnumber1/$fnumber2" | bc`
        exptime1=`echo $exptime | cut -d/ -f1`
        exptime2=`echo $exptime | cut -d/ -f2`
        exptime=`echo "scale=0; $exptime2/$exptime1" | bc`
        exiftext=`echo "$cameramodel ${focallength35}mm, F$fnumber, 1/$exptime, ISO $isospeed"`

        decho "EXIF: $exiftext"

        EXIF_FORMAT=""
        EXIF_OPTIONS=$1

        if [[ "$EXIF_OPTIONS" == *cameramodel* ]]; then
            EXIF_FORMAT="$cameramodel"
        fi
        if [[ "$EXIF_OPTIONS" == *focallength35* ]]; then
            EXIF_FORMAT="${EXIF_FORMAT} ${focallength35}mm"
        fi
        if [[ "$EXIF_OPTIONS" == *fnumber* ]]; then
            EXIF_FORMAT="${EXIF_FORMAT} F/${fnumber}"
        fi
        if [[ "$EXIF_OPTIONS" == *exptime* ]]; then
            EXIF_FORMAT="${EXIF_FORMAT} 1/${exptime}"
        fi
        if [[ "$EXIF_OPTIONS" == *isospeed* ]]; then
            EXIF_FORMAT="${EXIF_FORMAT} ${isospeed}"
        fi
        if [[ "$EXIF_OPTIONS" == *stripexif* ]]; then
            ARGS_STRIP_EXIF="Y"
        fi

        ARGS_ANNOTATION_TEXT=$EXIF_FORMAT
        decho "Annotation text: ${EXIF_FORMAT}"
    fi
}

# apply_config()
# {
#     if [ ! -z "$1" ]; then
#         decho "Apply config from $1:"
#         decho `cat $1`
#         source $1
#         [[ ! -z "$BOR_RESIZE" ]] && ARGS_RESIZE=$BOR_RESIZE
#         [[ ! -z "$BOR_QUALITY" ]] && ARGS_QUALITY=$BOR_QUALITY
#         [[ ! -z "$BOR_BORDER" ]] && ARGS_BORDER=$BOR_BORDER
#         [[ ! -z "$BOR_COLOR" ]] && ARGS_BORDERCOLOR=$BOR_COLOR
        
#         [[ ! -z "$BOR_ANNOTATION_TEXT" ]] && ARGS_ANNOTATION_TEXT=$BOR_ANNOTATION_TEXT
        
#         if [ ! -z "$BOR_EXIF_OPTIONS" ]; then
#             ARGS_EXIF_OPTIONS=$BOR_EXIF_OPTIONS
#         fi
#     fi
# }

if [ $# -eq 0 ]; then
    usage
    exit
fi

while getopts :b:de:f:q:r: OPTION
do
    case $OPTION in
        b)
            ARGS_BORDER=$OPTARG
            ;;
        d)
            DEBUG_ENABLED="Y"
            decho "Debug enabled"
            ;;
        e)
            ARGS_EXIF_OPTIONS=$OPTARG
            ;;
        f)
            ARGS_FONT_SIZE=$OPTARG
            ;;
        q)
            ARGS_QUALITY=$OPTARG
            ;;
        r)
            ARGS_RESIZE=$OPTARG
            ;;
        \?)
            usage
            ;;
    esac
done

if [ -z "$ARGS_RESIZE" -a -z "$ARGS_QUALITY" -a -z "$ARGS_BORDER" -a -z "$ARGS_ANNOTATION_TEXT" ]; then
    echo "What do you want to do, without necessary options specified?"
    exit
fi

shift $(($OPTIND - 1))

if [ $# -eq 0 ]; then
    echo "no input file specified."
    exit
fi

INPUT_FILE=$1
OUTPUT_FILE=$2
FILE_EXTENSION="${INPUT_FILE##*.}"

if [ ! -z "$ARGS_EXIF_OPTIONS" ]; then
    apply_exif_annotation $ARGS_EXIF_OPTIONS $INPUT_FILE
fi

if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="${INPUT_FILE%.*}_bor.${FILE_EXTENSION}"
    echo "No output file specified, use default output file: $OUTPUT_FILE"
fi

COMMAND="convert $INPUT_FILE "

if [ ! -z "$ARGS_RESIZE" ]; then
    COMMAND="${COMMAND} -resize ${ARGS_RESIZE} "
fi

if [ ! -z "$ARGS_QUALITY" ]; then
    COMMAND="${COMMAND} -quality ${ARGS_QUALITY}"
fi

if [ ! -z "$ARGS_RESIZE" -o ! -z "$ARGS_QUALITY" ]; then
    COMMAND="${COMMAND} ${OUTPUT_FILE}"
    decho "${COMMAND}"
    eval $COMMAND
    INPUT_FILE=$OUTPUT_FILE
fi

WIDTH_WO_BORDER=`eval "identify -format '%w' ${INPUT_FILE}"`
HEIGHT_WO_BORDER=`eval "identify -format '%h' ${INPUT_FILE}"`

if [ ! -z "$ARGS_BORDER" ]; then
    if [ -z "$ARGS_BORDERCOLOR" ]; then
        ARGS_BORDERCOLOR="White"
    fi
    COMMAND="convert ${INPUT_FILE} -bordercolor ${ARGS_BORDERCOLOR} -border ${ARGS_BORDER} ${OUTPUT_FILE}"
    decho "${COMMAND}"
    eval $COMMAND
    INPUT_FILE=$OUTPUT_FILE
fi

COMMAND=""

if [ ! -z "$ARGS_ANNOTATION_TEXT" -a ! -z "$ARGS_BORDER" ]; then
    WIDTH=`eval "identify -format '%w' ${INPUT_FILE}"`
    HEIGHT=`eval "identify -format '%h' ${INPUT_FILE}"`

    CALC_W="($WIDTH - $WIDTH_WO_BORDER) / 2"
    CALC_H="($HEIGHT - $HEIGHT_WO_BORDER) / 2"
    OFFSET_W=`echo "$CALC_W" | bc`
    OFFSET_H=`echo "$CALC_H" | bc`

    FONT_SIZE=
    if [[ "$ARGS_FONT_SIZE" == small ]]; then
        FONT_SIZE=`echo "${OFFSET_H} * 0.2" | bc`
    elif [[ "$ARGS_FONT_SIZE" == medium ]]; then
        FONT_SIZE=`echo "${OFFSET_H} * 0.3" | bc`
    else
        FONT_SIZE=`echo "${OFFSET_H} * 0.5" | bc`
    fi

    OFFSET_H=`echo "${OFFSET_H} - ${FONT_SIZE} - (${FONT_SIZE} / 10)" | bc`

    COMMAND="convert ${INPUT_FILE} -gravity southeast -pointsize ${FONT_SIZE} -annotate +${OFFSET_W}+${OFFSET_H} \"${ARGS_ANNOTATION_TEXT}\" ${OUTPUT_FILE}"
    decho "${COMMAND}"
    eval $COMMAND
fi

if [ ! -z "$ARGS_STRIP_EXIF" ]; then
    eval "exiftool -all= ${OUTPUT_FILE}"
fi
