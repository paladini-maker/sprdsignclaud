mkdir work
busybox unzip -oq original.zip -d work
mkdir -p boot/zzz
mkdir -p vbmeta/keys
mkdir output
tar xzvf avbtool.tgz -C vbmeta/
mv work/vbmeta.img vbmeta/keys/ 2>/dev/null || mv work/vbmeta-sign.img vbmeta/keys/vbmeta.img
busybox unzip -oq magisk.apk -d boot/zzz
mv main/boot_patch.sh boot/
mv main/sign_avb.sh vbmeta/
git clone https://github.com/TomKing062/vendor_sprd_proprietories-source_packimage.git
cp -a vendor_sprd_proprietories-source_packimage/sign_image/v2/prebuilt/* work/
cp -a main/config work/config-unisoc
if [ -d extra_key ]; then cp -f extra_key/* work/config-unisoc/; fi
cp vendor_sprd_proprietories-source_packimage/sign_image/v2/sign_image_v2.sh work/
gcc -o work/get-raw-image vendor_sprd_proprietories-source_packimage/sign_image/get-raw-image.c
chmod +x work/*
cd vendor_sprd_proprietories-source_packimage/sign_vbmeta
make
chmod +x generate_sign_script_for_vbmeta
cp generate_sign_script_for_vbmeta ../../vbmeta/keys/
cd ../../vbmeta/keys/
./generate_sign_script_for_vbmeta vbmeta.img
mv sign_vbmeta.sh ../
mv padding.py ../
cd ../..
cp work/config-unisoc/rsa4096_vbmeta.pem vbmeta/
chmod +x vbmeta/*
sudo rm -f /usr/bin/python /usr/bin/python3.6 /usr/bin/python3.6m /usr/local/bin/python
sudo ln -sf /usr/bin/python2.7 /usr/bin/python
cd work

# Process bootloader images
if [ -f "splloader.bin" ]; then
    ./get-raw-image "splloader.bin"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        mv splloader.bin u-boot-spl-16k.bin
    else
        exit 1
    fi
fi

if [ -f "u-boot-spl-16k-sign.bin" ]; then
    ./get-raw-image "u-boot-spl-16k-sign.bin"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        mv u-boot-spl-16k-sign.bin u-boot-spl-16k.bin
    else
        exit 1
    fi
fi

if [ -f "u-boot-spl-16k-emmc-sign.bin" ]; then
    ./get-raw-image "u-boot-spl-16k-emmc-sign.bin"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        mv u-boot-spl-16k-emmc-sign.bin u-boot-spl-16k-emmc.bin
    else
        exit 1
    fi
fi

if [ -f "u-boot-spl-16k-ufs-sign.bin" ]; then
    ./get-raw-image "u-boot-spl-16k-ufs-sign.bin"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        mv u-boot-spl-16k-ufs-sign.bin u-boot-spl-16k-ufs.bin
    else
        exit 1
    fi
fi

if [ -f "uboot.bin" ]; then
    ./get-raw-image "uboot.bin"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        mv uboot.bin u-boot.bin
    else
        exit 1
    fi
fi

if [ -f "sml.bin" ]; then
    ./get-raw-image "sml.bin"
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        exit 1
    fi
fi

if [ -f "tos.bin" ]; then
    ./get-raw-image "tos.bin"
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        exit 1
    fi
elif [ -f "trustos.bin" ]; then
    ./get-raw-image "trustos.bin"
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        mv "trustos.bin" "tos.bin"
    else
        exit 1
    fi
fi

./get-raw-image "teecfg.bin"
RETVAL=$?
if [ $RETVAL -ne 0 ]; then
    rm teecfg.bin 2>/dev/null
fi

cd ..

# Process boot image
mv work/boot.img boot/boot_real.img 2>/dev/null || mv work/boot-sign.img boot/boot_real.img
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    cp work/config-unisoc/rsa4096_boot.pem vbmeta/rsa4096_boot.pem
    cp -f work/config-unisoc/rsa4096_boot_pub.bin vbmeta/keys/rsa4096_boot_pub.bin
    cd boot
    cp -f boot_real.img boot.img
    ./boot_patch.sh
    cd ../vbmeta
    ./sign_avb.sh boot ../boot/boot.img ../boot/patched.img
    cp ../boot/patched.img ../output/boot.img
    cd ..
fi

# Process dtbo image
mkdir dtbo
mv work/dtbo.img dtbo/dtbo.img 2>/dev/null || mv work/dtbo-sign.img dtbo/dtbo.img
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    cp work/config-unisoc/rsa4096_boot.pem vbmeta/rsa4096_dtbo.pem
    cp -f work/config-unisoc/rsa4096_boot_pub.bin vbmeta/keys/rsa4096_dtbo_pub.bin
    cd vbmeta
    ./sign_avb.sh dtbo ../dtbo/dtbo.img ../dtbo/dtbo.img
    cp ../dtbo/dtbo.img ../output/dtbo.img
    cd ..
fi

# Process recovery image
mkdir recovery
mv work/recovery.img recovery/recovery.img 2>/dev/null || mv work/recovery-sign.img recovery/recovery.img
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    cp work/config-unisoc/rsa4096_recovery.pem vbmeta/
    cp -f work/config-unisoc/rsa4096_recovery_pub.bin vbmeta/keys/
    cd vbmeta
    ./sign_avb.sh recovery ../recovery/recovery.img ../recovery/recovery.img
    cp ../recovery/recovery.img ../output/recovery.img
    cd ..
fi

# Process system image (embedded in vbmeta_system)
mkdir system_vbmeta
mv work/vbmeta_system.img system_vbmeta/ 2>/dev/null || mv work/vbmeta_system-sign.img system_vbmeta/vbmeta_system.img
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    cp work/config-unisoc/rsa4096_vbmeta.pem vbmeta/rsa4096_vbmeta_system.pem
    cp -f work/config-unisoc/rsa4096_vbmeta_pub.bin vbmeta/keys/rsa4096_vbmeta_system_pub.bin
    cd vbmeta
    # Extract chain info from original vbmeta_system
    python avbtool make_vbmeta_image \
        --algorithm SHA256_RSA4096 \
        --key rsa4096_vbmeta_system.pem \
        --include_descriptors_from_image ../system_vbmeta/vbmeta_system.img \
        --output ../output/vbmeta_system.img
    cd ..
fi

# Process vendor image (embedded in vbmeta_vendor)
mkdir vendor_vbmeta
mv work/vbmeta_vendor.img vendor_vbmeta/ 2>/dev/null || mv work/vbmeta_vendor-sign.img vendor_vbmeta/vbmeta_vendor.img
RETVAL=$?
if [ $RETVAL -eq 0 ]; then
    cp work/config-unisoc/rsa4096_vbmeta.pem vbmeta/rsa4096_vbmeta_vendor.pem
    cp -f work/config-unisoc/rsa4096_vbmeta_pub.bin vbmeta/keys/rsa4096_vbmeta_vendor_pub.bin
    cd vbmeta
    # Extract chain info from original vbmeta_vendor
    python avbtool make_vbmeta_image \
        --algorithm SHA256_RSA4096 \
        --key rsa4096_vbmeta_vendor.pem \
        --include_descriptors_from_image ../vendor_vbmeta/vbmeta_vendor.img \
        --output ../output/vbmeta_vendor.img
    cd ..
fi

# Sign main vbmeta with chain descriptors
cd vbmeta
./sign_vbmeta.sh
python padding.py
cp vbmeta-sign-custom.img ../output/vbmeta.img

cd ../work
./sign_image_v2.sh
cp *-sign.bin ../output/
cd ..
zip -r -v resigned.zip output
