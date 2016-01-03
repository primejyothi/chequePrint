#! /usr/bin/env bash

# Script to generate print cheques based on text templates using postscript
# Prime Jyothi 20160101
# primejyothi [at] gmail [dot] com

# Log functions
. ./logs.sh

# dbgFlag=y

function help ()
{
cat << end_help
Usage : `basename $0` [-h] -f profileFile -o outputFile -p Payee \
-a amount -w Words -d date
	-h : Display this help message
	-f : Profile file
	-o : Output ps file
	-s : Print a sample profile file
	-p : Payee Name
	-a : Amount in figures
	-w : Amount in words
	-d : Date in dd-mm-yyyy format
end_help
}

function printSample ()
{
	dbg $LINENO "printSample profile file function"	
	cat << end_sample
# Width of the cheque
cWidth=576
# Height of the cheque
cLen=261
# Comment
 # Comment2

# Coordinates of payee line
pPos=70 189

# Coordinates of Amount in words line
w1Pos=70 162

# Coordinates of amount line
aPos=446 140

# Coordinates of Date
# d1/d2/m1/m2/y1... are ignored if dPos is present
# dPos=440 218

# Coordinates of day, month & year
# These values are ignored if dPos is present
d1Pos=440 218
d2Pos=454 218
m1Pos=468 218
m2Pos=482 218
y1Pos=496 218
y2Pos=510 218
y3Pos=524 218
y4Pos=538 218

acPText=AC PAYEE

# AC Payee start coordinates
acPos=40 200

# Font size of AC Payee text
acFontSize=12

# Angle of the Ac Payee text
acAngle=45

end_sample
}

function wPs  ()
{
	echo "$@" >> ${oFile}
}

function xOff ()
{
	# Return the x offset for a specified length at an angle
	# x offset = cos (angle) * length, the angle need to be converted
	# into radians first as cos expects in put in radians.
	angle=$1
	length=$2

	echo $angle $length  |
	awk '{res = ( cos ( (atan2 (0, -1)/ 180) * $1) * $2 ); 
	if (res != int(res)) {res = int(res) + 1;}; print res}'
}

function yOff ()
{
	# Return the y offset for a specified length at an angle
	# x offset = sin (angle) * length, the angle need to be converted
	# into radians first as sin expects in put in radians.
	# Add one to the offset as the int will mostly work as floor ().
	angle=$1
	length=$2

	echo $angle $length |
	awk '{res = ( sin ( (atan2 (0, -1)/ 180) * $1) * $2 );
	if (res != int(res)) {res = int(res) + 1;}; print res}'
}

function findWidth ()
{
	str=$1
	font=$2
	size=$3
	# Can't get gs to take the shell variable directly, build the gs command,
	# write to a temp file and execute
	cmd=`echo "gs -dQUIET -sDEVICE=nullpage 2>/dev/null - \
   <<<'$size /"$font" findfont exch scalefont setfont ($str)\
   stringwidth pop =='"`
	echo $cmd > gs.cmd
	width=`bash gs.cmd`
	echo $width | awk '{print (int ($1))}'
	rm -f gs.cmd
}

while getopts f:o:p:a:w:d:hs args
do
	case $args in
		h)
			help
			exit 0
			;;
		f)
			pFile="$OPTARG"
			dbg $LINENO "pFile [$pFile]"
			;;
		s)
			printSample
			exit 0
			;;
		o)
			oFile="$OPTARG"
			dbg $LINENO "Out file [$oFile]"
			;;
		p)
			payee="$OPTARG"
			dbg $LINENO "Payee [$payee]"
			;;
		a)
			amt="$OPTARG"
			dbg $LINENO "Amount [$amt]"
			;;
		d)
			date="$OPTARG"
			dbg $LINENO "Date [$date]"
			;;
		w)
			words="$OPTARG"
			dbg $LINENO "Amount in words [$words]"
			;;
	esac
done


# Input args validations

if [ ! -z "$pFile" -a ! -r "$pFile" ]
then
	err $LINENO "Unable to read input profile file $pFile, exiting."
	exit 2
fi

# Read the profile file
while read line
do

	# Ignore lines commented by # character.
	echo "$line" | grep -q "[ ]*#"
	res=$?
	if [[ $res -eq 0 ]]
	then
	   continue
	fi  

	dbg $LINENO "$line"
	# Skip empty lines
	if [[ -z "$line" ]]
	then
		continue
	fi

	# Read the key value pairs
	key=`echo $line | awk -F"=" '{print $1}'`
	value=`echo $line | awk -F"=" '{print $2}'`

	dbg $LINENO "key=[$key]"
	dbg $LINENO "value=[$value]"

	# Assign the values to respective variables.

	case $key in
		"cLen" )
			cLen=$value
			;;
		"cWidth" )
			cWidth=$value
			;;
		"pPos" )
			pPos=$value
			;;
		"w1Pos" )
			w1Pos=$value
			;;
		"aPos" )
			aPos=$value
			;;
		"dPos" )
			dPos=$value
			;;
		"d1Pos" )
			d1Pos=$value
			;;
		"d2Pos" )
			d2Pos=$value
			;;
		"m1Pos" )
			m1Pos=$value
			;;
		"m2Pos" )
			m2Pos=$value
			;;
		"y1Pos" )
			y1Pos=$value
			;;
		"y2Pos" )
			y2Pos=$value
			;;
		"y3Pos" )
			y3Pos=$value
			;;
		"y4Pos" )
			y4Pos=$value
			;;
		"acPos" )
			acPos=$value
			;;
		"acFontSize" )
			acFontSize=$value
			;;
		"acAngle" )
			acAngle=$value
			;;
		"acPText" )
			acPText=$value
			;;
		* )
			err $LINENO "Invalid key $key"
			# exit 3
			;;
	esac

	
done < "$pFile"

# Generate the postscript file
wPs newpath
wPs "<< /PageSize [$cWidth $cLen] /Orientation 0 >> setpagedevice"
wPs /Times-Roman findfont
wPs 14 scalefont
wPs setfont
wPs newpath
wPs % Payee Info
wPs $pPos moveto
wPs "($payee) show"
wPs ""

wPs % Amount in Words
wPs $w1Pos moveto
wPs "($words) show"
wPs ""

wPs "% Amount in figures"
wPs "$aPos moveto"
wPs "($amt) show"
wPs ""

# Date
wPs "% Date"
if [[ ! -z "$dPos" ]]
then
	wPs "$dPos moveto"
	wPs "(${date}) show"
else
	
	wPs "$d1Pos moveto"
	wPs "(${date:0:1}) show"

	wPs "$d2Pos moveto"
	wPs "(${date:1:1}) show"

	wPs "$m1Pos moveto"
	wPs "(${date:3:1}) show"

	wPs "$m2Pos moveto"
	wPs "(${date:4:1}) show"

	wPs "$y1Pos moveto"
	wPs "(${date:6:1}) show"

	wPs "$y2Pos moveto"
	wPs "(${date:7:1}) show"

	wPs "$y3Pos moveto"
	wPs "(${date:8:1}) show"

	wPs "$y4Pos moveto"
	wPs "(${date:9:1}) show"
fi

if [[ ! -z "$acPText" ]]
then
	# Parallel lines
	acPosX=`echo $acPos | awk '{print $1}'`
	acPosY=`echo $acPos | awk '{print $2}'`

	dbg $LINENO "acPos [$acPos]"
	dbg $LINENO "acPosX [$acPosX]"
	dbg $LINENO "acPosY [$acPosY]"
	dbg $LINENO "acFontSize [$acFontSize]"

	# Find the length of the line that will cover the AC Payee text
	textLen=`findWidth "$acPText" "Times-Roman" $acFontSize`
	dbg $LINENO "textLen [$textLen]"

	xoff=`xOff $acAngle $textLen`
	yoff=`yOff $acAngle $textLen`

	wPs ""
	wPs "% Parallel lines"
	wPs "newpath"
	wPs "% Upper line"
	# Place the lines above & below the AC Payee text
	fxoff=`xOff $((90 - $acAngle)) $acFontSize`
	fyoff=`yOff $((90 - $acAngle)) $acFontSize`
	dbg $LINENO "fxoff [$fxoff]"
	dbg $LINENO "fyoff [$fyoff]"

	# Line offsets
	# Upper line
	wPs "$(($acPosX - $fxoff)) $(($acPosY + $fyoff -2 )) moveto"
	wPs "$(($acPosX - $fxoff + $xoff)) $(($acPosY + $fyoff + $yoff - 2)) lineto"

	# Lower line
	wPs ""
	wPs "% Lower line"
	wPs "$acPosX $(($acPosY - 3)) moveto"
	wPs "$(($acPosX + $xoff)) $(($acPosY + $yoff - 3 )) lineto"
	wPs "1 setlinewidth"
	wPs "stroke"
	wPs ""

	# Print the AC Payee lines
	wPs "% A/C Payee"
	wPs "/Times-Roman findfont"
	wPs "$acFontSize scalefont"
	wPs "setfont"
	wPs "$acPos moveto"
	wPs "$acAngle rotate"
	wPs "($acPText) show"
	wPs ""
fi

wPs showpage

log $LINENO "Ouputfile ${oFile} generated, convert to pdf using \
ps2pdf ${oFile}"
log $LINENO "Print the pdf file using \
lpr -o PageSize=Custom.9x20cm ${oFile%ps}pdf, change the paper size \
as appropriate."

