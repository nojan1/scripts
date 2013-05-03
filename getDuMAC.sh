#!/bin/sh

MACFILE="macs"
INTERFACE="enp4s0"

function setmac {
	if [ -f "/usr/bin/macchanger" ]; then
		sudo macchanger -b -m $2 $1
	else
		sudo ifconfig $1 down
		sudo ifconfig $1 hw ether $2
		sudo ifconfig $1 up
	fi
}

echo "Enter computer name: "
read name

newmac=$(grep -i "$name" $MACFILE | cut -d ";" -f 2)
if [ -z "$newmac" ]; then
	echo "No MAC-address was found for that computer name"
	echo "Enter it now? (y/N)"
	read confirmation
	if [ "$confirmation" == "y" ]; then 
		echo "Enter MAC-address for computer '$name'; "
		read newmac
		echo "$name;$newmac" >> $MACFILE
	else
		exit 0
	fi
else
	echo "Search matched '$(grep -i "$name" $MACFILE | cut -d ";" -f 1)'"
fi

echo "MAC-address for interface $INTERFACE will not be set to; $newmac"
echo "Continue? (Y/n)"

read confirmation
if [ "$confirmation" == "n" ]; then 
	exit 0
fi

setmac "$INTERFACE" "$newmac"
echo "All done, exiting"
