#!/bin/bash

if [ "$UID" -ne "0" ]; then
	echo "Must be root"
	exit
fi

case "$1" in 
mount)

FILE="$2"
OFFSET="$3"
MOUNTPOINT="$4"

LOOPDEV=$(losetup --find --show --offset "$OFFSET" "$FILE")

if [ "$?" -ne "0" ]; then
	echo "Losetup failed!"
	exit
fi

MAPPER=$(echo "$LOOPDEV" | sed 'y|/|n|')

echo "$LOOPDEV"
echo "$MAPPER"

cryptsetup luksOpen "$LOOPDEV" "$MAPPER"

mount "/dev/mapper/$MAPPER" "$MOUNTPOINT"

;;
umount )
 FILE=$(realpath "$2")

 LOOPDEV="$(losetup -a | grep "$FILE" | cut -d ":" -f 1)"
 if [ -z "$LOOPDEV" ]; then
  echo "No loopback device found"
  exit
 fi

 MAPPER=$(echo "$LOOPDEV" | sed 'y|/|n|')

 umount /dev/mapper/$MAPPER
 cryptsetup luksClose $MAPPER
 losetup -d $LOOPDEV

;;
create )

FILE="$2"
SIZE="$3"
FS="$4"
OUT="$5"

if [ ! -f "$FILE" ]; then
	echo "File not found"
	exit
fi


dd if=/dev/zero of=.nullfile bs=$SIZE count=1 &> /dev/null

LOOPDEV=$(losetup --find --show .nullfile)

cryptsetup -c aes-xts-plain -y -s 512 luksFormat $LOOPDEV
cryptsetup luksDump $LOOPDEV

MAPPER=$(echo "$LOOPDEV" | sed 'y|/|n|')

echo "Enter password again: "
cryptsetup luksOpen "$LOOPDEV" "$MAPPER"

mkfs -t "$FS" "/dev/mapper/$MAPPER"

cryptsetup luksClose "$MAPPER"
losetup -d "$LOOPDEV"

OFFSET=$(wc -c "$FILE" | cut -d ' ' -f 1)

echo "Note: Offset is $OFFSET you will need this to mount! Offset will also be addded to the end of the file, use tail to see it"
cat "$FILE" .nullfile > "$OUT"
echo $OFFSET >> "$OUT"
rm .nullfile

;;
*)
echo "To Create;"
echo "Arguments: <INPUT FILE> <PARTITION SIZE> <FILE SYSTEM> <OUTPUT FILE>"
echo "------------"
echo "To Mount;"
echo "Arguments: <FILE> <OFFSET> <MOUNTPOINT>"
echo "-----------"
echo "To unmount;"
echo "Arguments: <FILE>"
echo "-----------"
;;
esac
