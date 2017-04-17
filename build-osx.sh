echo ">>> Creating new MikeOS floppy image..."
rm -rf disk_images
mkdir -p disk_images

dd if=/dev/zero bs=1024 count=1440 > disk_images/mikeos.flp
/usr/local/Cellar/dosfstools/4.1/sbin/mkfs.fat disk_images/mikeos.flp
cp disk_images/mikeos.flp disk_images/mikeos.dmg

nasm -O0 -w+orphan-labels -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit

cd source
rm kernel.bin
nasm -O0 -w+orphan-labels -f bin -o kernel.bin kernel.asm || exit
cd ..

cd programs
rm *.bin
for i in *.asm
do
    nasm -O0 -w+orphan-labels -f bin $i -o `basename $i .asm`.bin || exit
done

cd ..

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
echo  qemu-system-i386 -cdrom disk_images/mikeos.iso
