#!/bin/sh
#############################################################################
# 					  A makefile to assemble SCP/BIOS.					    #
#############################################################################
# nasm options are:															#
# -O0 = NO OPTIMISATIONS, -l = Listing file.								#
#																			#
# Three make files:															#
# make => Assembles the SCP/BIOS image and writes it to sector 34 of the 	#
# 		  test disk image (sector 34 is the start of the FAT12/16 data area)#
#																			#
# make loader => Assembles the example SCP/BIOS compatible boot loader and 	#
#				 writes it to sector 0 of the test disk image (the boot		#
#				 sector of any medium and the default sector read by a 		#
#			     system's firmware BIOS if it is IBM compatible)			#
# 																			#
# make fresh => Creates a fresh disk image and assembles a new copy of both	#
#				the bootloader and SCP/BIOS and puts them in the 			#
#				aforementioned locations.									#
#																			#
# If you wish to build your own copy of SCP/BIOS simply run build or 		#
# build fresh.																#
#																			#
# If you wish to build your own copy of SCP/BIOS for use on a mass storage 	#
# medium with a different filesystem to FAT12 (the filesystem in the 		#
# example bootloader, loader.asm, provided in the folder called Boot) 		#
# simply edit or replace the bootloader in the Boot folder 					#
# (for simplicity, you can call this file loader.asm too) and change the 	#
# sector you write scpbios.bin to in the dd command from seek=34 to 		#
# seek=CHOSEN_SECTOR_NUMBER													#
#############################################################################

assemble:
	nasm scpbios.asm -o ./Binaries/scpbios.bin -f bin -l scpbios.lst -O0
	dd if=./Binaries/scpbios.bin of=./Images/TestImage.ima bs=512 seek=34 conv=notrunc
	cp ./Images/TestImage.ima ./Images/TestImageMSD.ima

#Add a new boot sector to current image
loader:
	nasm ./Boot/loader.asm -o ./Binaries/loader.bin -f bin -l ./Boot/loader.lst -O0
	dd if=./Binaries/loader.bin of=./Images/TestImage.ima bs=512 count=1 conv=notrunc
	cp ./Images/TestImage.ima ./Images/TestImageMSD.ima

#Create a fresh disk image
fresh:
	dd if=/dev/zero of=./MyDisk.IMA bs=512 count=2880 conv=notrunc

	nasm ./Boot/loader.asm -o ./Binaries/loader.bin -f bin -l ./Boot/loader.lst -O0
	dd if=./Binaries/loader.bin of=./Images/TestImage.ima bs=512 count=1 conv=notrunc

	nasm scpbios.asm -o ./Binaries/scpbios.bin -f bin -l scpbios.lst -O0
	dd if=./Binaries/scpbios.bin of=./Images/TestImage.ima bs=512 seek=34 conv=notrunc

	cp ./Images/TestImage.ima ./Images/TestImageMSD.ima

#++++++++++++++++
#Reference info
#++++++++++++++++
#To create new disk image
#dd if=/dev/zero of=./MyDisk.IMA bs=512 count=numberOfSectors conv=notruc

#To add a Bootsector to new disk image
#dd if=./scpdosbs.bin of=./MyDisk.IMA bs=512 count=1 conv=notrunc

#To add a second program at sector 82 on the disk we do the following
#nasm PROG2.ASM -o prog2.bin -f bin -O0
#dd if=./prog2.bin of=./MyDisk.IMA bs=512 oseek=82 conv=notrunc