prereq() {
    if [ ! -x /usr/local/bin/nasm ]; then
	echo >&2 "do 'brew install nasm'"
	return 1
    else
	echo >&2 "you have nasm: good."
    fi
    if [ ! -x /usr/local/Cellar/dosfstools/4.1/sbin/mkfs.fat ]; then
	echo >&2 "do 'brew install dosfstools'"
	return 1
    else
	echo >&2 "you have dosfstools: good."
    fi
    if [ ! -x /usr/local/bin/qemu-system-i386 ]; then
	echo >&2 "do 'brew install qemu-system-i386'"
	return 1
    else
	echo >&2 "you have qemu: good."
    fi
     
}    

prereq
retval=$?

if [ "$retval" == 1 ]; then
    echo "please install prerequisites and try again."
    exit 1
fi
  
echo ">>> Compile bootload.bin..."

nasm -O0 -w+orphan-labels -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit

echo ">>> Compile kernel..."

cd source
rm kernel.bin
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..

echo ">>> Compile user programs..."

cd programs
rm *.bin
for i in *.asm
do
    nasm -O0 -w+orphan-labels -f bin $i -o `basename $i .asm`.bin || exit
done

cd ..

echo ">>> Creating iso.."

rm -rf disk_images
mkdir -p disk_images
dd if=/dev/zero bs=1024 count=1440 > disk_images/mikeos.dmg
/usr/local/Cellar/dosfstools/4.1/sbin/mkfs.fat disk_images/mikeos.dmg
dd conv=notrunc if=source/bootload/bootload.bin of=disk_images/mikeos.dmg
dev=`hdid -nobrowse -nomount disk_images/mikeos.dmg`
mkdir tmp-loop && mount -t msdos ${dev} tmp-loop && cp source/kernel.bin tmp-loop/
cp programs/*.bin programs/*.bas programs/sample.pcx tmp-loop
diskutil umount tmp-loop
hdiutil detach ${dev}
rm -rf tmp-loop
rm -f disk_images/mikeos.iso
mkisofs -quiet -V 'MIKEOS' -input-charset iso8859-1 -o disk_images/mikeos.iso -b mikeos.dmg disk_images/ 
ls -lt disk_images
echo "Now you can do:"
echo "  qemu-system-i386 -cdrom disk_images/mikeos.iso"
