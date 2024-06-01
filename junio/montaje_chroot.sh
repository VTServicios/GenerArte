#!/bin/bash

# Punto de montaje principal
MOUNT_POINT="/mnt"

# Función para listar discos y particiones
list_disks_and_partitions() {
    lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT
}

# Función para seleccionar una partición
select_partition() {
    echo "Introduce el nombre de la partición que quieres montar (por ejemplo, sda1):"
    read partition
    echo "/dev/$partition"
}

# Función para montar las particiones
mount_partitions() {
    ROOT_PARTITION=$(select_partition)

    echo "Montando la partición raíz en $MOUNT_POINT..."
    mount $ROOT_PARTITION $MOUNT_POINT

    echo "¿Quieres montar una partición /boot separada? (s/n)"
    read answer
    if [ "$answer" == "s" ]; then
        BOOT_PARTITION=$(select_partition)
        echo "Montando la partición /boot en $MOUNT_POINT/boot..."
        mount $BOOT_PARTITION $MOUNT_POINT/boot
    fi

    echo "¿Quieres montar una partición EFI separada? (s/n)"
    read answer
    if [ "$answer" == "s" ]; then
        EFI_PARTITION=$(select_partition)
        echo "Montando la partición EFI en $MOUNT_POINT/boot/efi..."
        mkdir -p $MOUNT_POINT/boot/efi
        mount $EFI_PARTITION $MOUNT_POINT/boot/efi
    fi

    echo "Montando sistemas de archivos necesarios..."
    mount --bind /dev $MOUNT_POINT/dev
    mount --bind /proc $MOUNT_POINT/proc
    mount --bind /sys $MOUNT_POINT/sys
    mount --bind /run $MOUNT_POINT/run
}

# Función para desmontar las particiones
umount_partitions() {
    echo "Desmontando sistemas de archivos..."
    umount $MOUNT_POINT/run
    umount $MOUNT_POINT/dev
    umount $MOUNT_POINT/proc
    umount $MOUNT_POINT/sys

    if [ -n "$EFI_PARTITION" ]; then
        echo "Desmontando la partición EFI..."
        umount $MOUNT_POINT/boot/efi
    fi

    if [ -n "$BOOT_PARTITION" ]; then
        echo "Desmontando la partición /boot..."
        umount $MOUNT_POINT/boot
    fi

    echo "Desmontando la partición raíz..."
    umount $MOUNT_POINT
}

# Comprobar si se proporcionó un argumento
if [ "$1" == "enter" ]; then
    echo "Listando discos y particiones disponibles..."
    list_disks_and_partitions
    mount_partitions
    echo "Entrando en chroot..."
    chroot $MOUNT_POINT
elif [ "$1" == "exit" ]; then
    umount_partitions
else
    echo "Uso: $0 {enter|exit}"
    echo "enter - Montar particiones y entrar en chroot"
    echo "exit  - Desmontar particiones"
fi
