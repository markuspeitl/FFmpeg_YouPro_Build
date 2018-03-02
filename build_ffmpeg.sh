#!/bin/bash

set -e

ORIGINAL_PATH=${PATH}

if [ ! "$1" = "" ] && [ ! "$1" = "--init" ] && [ ! "$1" = "--reset" ]; then
    printf "Usage:\n"
    printf "    $0 --init\n"
    printf "            To download NDK, FFMPEG, and the dependencies.\n"
    printf "    $0\n"
    printf "            To build everything.\n"
    printf "    $0 --reset\n"
    printf "            To build everything, forcing a 'git checkout -- .' on all components.\n"
    exit 1
fi

if [ ! -n "${DIR_NDK}" ]; then
    printf "You need to specify the following environment variables:\n"
    printf "    DIR_NDK - NDK root directory [DO NOT USE SYMBOLIC LINKS]\n"
    exit 1
fi

LOG_FILE="$(pwd)/build_ffmpeg.log"
printf "" > ${LOG_FILE}

# Initialize ndk and toolchain.

if [ "$1" = "--init" ]; then

    # Download ndk.

    #printf "NDK\n"

    #if [ ! -f android-ndk-r12b-darwin-x86_64.zip ]; then
        #printf "    downloading r12b for mac\n"
        #curl "https://dl.google.com/android/repository/android-ndk-r12b-darwin-x86_64.zip" \
            #-o android-ndk-r12b-darwin-x86_64.zip \
            #>> ${LOG_FILE} 2>&1
    #fi

    #printf "    unzipping\n"
    #unzip android-ndk-r12b-darwin-x86_64.zip \
        #>> ${LOG_FILE} 2>&1

    #printf "    moving to ${DIR_NDK}\n"
    #rm -rf ${DIR_NDK} || true
    #mkdir -p ${DIR_NDK} \
        #>> ${LOG_FILE} 2>&1
    #mv android-ndk-r12b/* ${DIR_NDK} \
    #    >> ${LOG_FILE} 2>&1

    #printf "    done\n"

    # Download sources.
    printf "SOURCES\n"

    printf "    copying ffmpeg v3.3.3\n"
    cp -r $(pwd)/FFmpeg-n3.3.3 ${DIR_NDK}/sources/ffmpeg \
	>> ${LOG_FILE} 2>&1
    
    cd ${DIR_NDK}/sources \
        >> ${LOG_FILE} 2>&1

    printf "    cloning yasm\n"
    git clone --progress git://github.com/yasm/yasm.git \
        >> ${LOG_FILE} 2>&1

    # mekame edited - START

    #printf "    cloning ogg\n"
    #git clone --progress git://git.xiph.org/mirrors/ogg.git \
    #    >> ${LOG_FILE} 2>&1

    #printf "    downloading vorbis\n"
    #curl "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.4.tar.gz" \
    #    -o libvorbis-1.3.4.tar.gz \
    #    >> ${LOG_FILE} 2>&1
    #tar xzvf libvorbis-1.3.4.tar.gz \
    #    >> ${LOG_FILE} 2>&1
    #rm libvorbis-1.3.4.tar.gz \
    #    >> ${LOG_FILE} 2>&1
    #rm -rf libvorbis \
    #    >> ${LOG_FILE} 2>&1
    #mv libvorbis-1.3.4 libvorbis \
    #    >> ${LOG_FILE} 2>&1

    printf "    cloning vpx\n"
    (git clone --progress https://chromium.googlesource.com/webm/libvpx.git libvpx) \
        >> ${LOG_FILE} 2>&1

    printf "    downloading openh264 v1.5\n"
    wget "https://github.com/cisco/openh264/archive/v1.5.0.tar.gz" \
        >> ${LOG_FILE} 2>&1
    tar -zxf v1.5.0.tar.gz \
	>> ${LOG_FILE} 2>&1
    rm -f v1.5.0.tar.gz
    rm -rf openh264 \
	>> ${LOG_FILE} 2>&1
    mv openh264-1.5.0 openh264 \
	>> ${LOG_FILE} 2>&1

    #printf "    cloning ffmpeg\n"
    #(git clone --progress git://source.ffmpeg.org/ffmpeg.git ffmpeg) \
    #    >> ${LOG_FILE} 2>&1

    # mekame edited - END

    SOURCE_LIST=$(ls ${DIR_NDK}/sources)
    printf "    done\n"
    printf "${SOURCE_LIST}"
    exit 0
fi

if [ ! -d "${DIR_NDK}/sources/ffmpeg" ]; then
    printf "NDK not found. Run './build_ffmpeg.sh --init' to download everything.\n"
    printf "Dir =${DIR_NDK}\n"
    exit 1
fi

# Verify input variables. PIE_FLAGS do not need to be set and are disabled by default.
if [ ! -n "${NUM_JOBS}" ] || [ ! -n "${LEVEL}" ] || [ ! -n "${CPU}" ] ||
   [ ! -n "${PREFIX}" ] || [ ! -n "${TOOLCHAIN_PREFIX}" ] || [ ! -n "${LIBVPX_TARGET}" ]; then

    printf "You need to specify the following environment variables:\n"
    printf "    NUM_JOBS - Number of threads to use for make [1:]\n"
    printf "    LEVEL - Android platform level, should be one from\n"
    printf "          ~/\$DIR_NDK/platforms/android-* [9:19]\n"
    printf "    CPU - Android CPU architecture, should be one from\n"
    printf "          ~/\$DIR_NDK/platforms/android-\$LEVEL/arch-* [arm / x86]\n"
    printf "    PREFIX - Android toolchain executable prefix\n"
    printf "             [arm-linux-androideabi / i686-linux-android]\n"
    printf "    TOOLCHAIN_PREFIX - Android toolchain folder prefix\n"
    printf "             [arm-linux-androideabi / x86]\n"
    printf "    LIBVPX_TARGET - See \"libvpx/configure --help\" [armv7 / x86]\n"
    exit 1
fi

# Determine the output directory and put PIE executables in their own separate path.
# Also set whether --enable-pic is passed to FFmpeg's configuration to generate PIE executables.
if [[ $PIE_FLAGS ]]; then
    ffmpegOutputDir=${DIR_NDK}/bin/${CPU}/pie
    enablePic="--enable-pic"
else
    ffmpegOutputDir=${DIR_NDK}/bin/${CPU}
    enablePic=""
fi

# Setup the android ndk toolchain to cross compile.
DIR_SYSROOT=${DIR_NDK}/platforms/android-${LEVEL}/arch-${CPU}/usr

if [ ! -d "${DIR_SYSROOT}/bin" ]; then
    printf "TOOLCHAIN\n"
    TOOLCHAIN=${TOOLCHAIN_PREFIX}-4.9

    printf "    generating\n"
    ${DIR_NDK}/build/tools/make-standalone-toolchain.sh \
        --platform=android-${LEVEL} \
        --toolchain=${TOOLCHAIN} \
        --install-dir=${DIR_SYSROOT} \
        --stl=stlport \
        >> ${LOG_FILE} 2>&1

    printf "    done ${DIR_SYSROOT}\n"
fi

# Make the executables executable.
chmod -R u+x ${DIR_NDK} \
    >> ${LOG_FILE} 2>&1

# Build YASM.
printf "YASM\n"
printf "${DIR_NDK}/sources/yasm";
cd ${DIR_NDK}/sources/yasm \
    >> ${LOG_FILE} 2>&1

if [ "$1" = "--reset" ] || [ "$1" = "--init" ]; then
    printf "    resetting\n"
    git checkout -- . \
        >> ${LOG_FILE} 2>&1
    (git checkout 4c2772c3f90fe66c21642f838e73dba20284fb0a \
        >> ${LOG_FILE} 2>&1) || true
fi

printf "    cleaning\n"
(make clean \
    >> ${LOG_FILE} 2>&1) || true

printf "    configuring\n"
bash autogen.sh --host=${PREFIX} --prefix=${DIR_SYSROOT} \
    >> ${LOG_FILE} 2>&1

printf "    building\n"
make -j${NUM_JOBS} \
    >> ${LOG_FILE} 2>&1

printf "    installing\n"
make install \
    >> ${LOG_FILE} 2>&1

printf "    done\n    "
ls ${DIR_SYSROOT}/lib | grep libyasm.a
# Done building libyasm.a.


# Build libogg.
#printf "LIBOGG\n"
#export PATH=${ORIGINAL_PATH}:${DIR_SYSROOT}/bin
#export RANLIB=${DIR_SYSROOT}/bin/${PREFIX}-ranlib
#cd ${DIR_NDK}/sources/ogg \
#    >> ${LOG_FILE} 2>&1

#if [ "$1" = "--reset" ] || [ "$1" = "--init" ]; then
#    printf "    resetting\n"
#    git checkout -- . \
#        >> ${LOG_FILE} 2>&1
#    git checkout ab78196fd59ad7a329a2b19d2bcec5d840a9a21f \
#        >> ${LOG_FILE} 2>&1 || true
#fi

#printf "    cleaning\n"
#make clean \
#    >> ${LOG_FILE} 2>&1 || true

#printf "    configuring\n"
#./autogen.sh --prefix=${DIR_SYSROOT} --host=${PREFIX} --with-sysroot=${DIR_SYSROOT} \
#    --disable-shared \
#    >> ${LOG_FILE} 2>&1

#printf "    building\n"
#make -j${NUM_JOBS} \
#    >> ${LOG_FILE} 2>&1

#printf "    installing\n"
#make install \
#    >> ${LOG_FILE} 2>&1

#printf "    done\n    "
#ls ${DIR_SYSROOT}/lib | grep libogg.a
#unset RANLIB
#export PATH=${ORIGINAL_PATH}
# Done building libogg.a and libogg.la.


# Build libvorbis.
#printf "LIBVORBIS\n"
#export CC=${DIR_SYSROOT}/bin/${PREFIX}-gcc
#export CXX=${DIR_SYSROOT}/bin/${PREFIX}-g++
#export LD=${DIR_SYSROOT}/bin/${PREFIX}-ld
#export STRIP=${DIR_SYSROOT}/bin/${PREFIX}-strip
#export NM=${DIR_SYSROOT}/bin/${PREFIX}-nm
#export AR=${DIR_SYSROOT}/bin/${PREFIX}-ar
#export AS=${DIR_SYSROOT}/bin/${PREFIX}-as
#export RANLIB=${DIR_SYSROOT}/bin/${PREFIX}-ranlib
#cd ${DIR_NDK}/sources/libvorbis \
#    >> ${LOG_FILE} 2>&1

#printf "    cleaning\n"
#make clean \
#    >> ${LOG_FILE} 2>&1 || true

#printf "    configuring\n"
#./configure --prefix=${DIR_SYSROOT} --host=${PREFIX} --with-sysroot=${DIR_SYSROOT} \
#    --disable-shared \
#    >> ${LOG_FILE} 2>&1

#printf "    building\n"
#make -j${NUM_JOBS} \
#    >> ${LOG_FILE} 2>&1

#printf "    installing\n"
#make install \
#    >> ${LOG_FILE} 2>&1

#printf "    done\n    "
#ls ${DIR_SYSROOT}/lib | grep libvorbis.a
#unset CC CXX LD STRIP NM AR AS RANLIB
# libvorbis.a done.

# Build libvpx.
printf "LIBVPX\n"
export CROSS=${DIR_SYSROOT}/bin/${PREFIX}-
cd ${DIR_NDK}/sources/libvpx \
    >> ${LOG_FILE} 2>&1

if [ "$1" = "--reset" ] || [ "$1" = "--init" ]; then
    printf "    resetting\n"
    git checkout -- . \
        >> ${LOG_FILE} 2>&1
    git checkout tags/v1.6.1 \
        >> ${LOG_FILE} 2>&1
    git checkout -B v1.6.1 \
        >> ${LOG_FILE} 2>&1
    git checkout v1.6.1 \
        >> ${LOG_FILE} 2>&1
    git pull origin tags/v1.6.1 \
        >> ${LOG_FILE} 2>&1
fi

printf "    cleaning\n"
make clean \
    >> ${LOG_FILE} 2>&1 || true

printf "    configuring\n"
./configure --target=${LIBVPX_TARGET}-android-gcc --sdk-path=${DIR_NDK} --prefix=${DIR_SYSROOT} \
    --enable-vp9 --disable-examples --disable-runtime-cpu-detect --disable-realtime-only \
    --enable-vp8-encoder --enable-vp8-decoder \
    >> ${LOG_FILE} 2>&1

printf "    building\n"
make -j${NUM_JOBS} \
    >> ${LOG_FILE} 2>&1

printf "    installing\n"
make install \
    >> ${LOG_FILE} 2>&1

printf "    done\n    "
ls ${DIR_SYSROOT}/lib | grep libvpx.a
unset CROSS
# libvpx.a finished building.

# mekame edited - START
# Build openh264
printf "OPENH264\n"
cd ${DIR_NDK}/sources/openh264 \
    >> ${LOG_FILE} 2>&1

printf "    building\n"
make OS=android NDKROOT=${DIR_NDK} TARGET=android-16 ARCH=arm PREFIX=${DIR_SYSROOT} \
    >> ${LOG_FILE} 2>&1
printf "    installing\n"
make OS=android NDKROOT=${DIR_NDK} TARGET=android-16 ARCH=arm PREFIX=${DIR_SYSROOT} install \
    >> ${LOG_FILE} 2>&1
printf "    cleaning\n"
make OS=android NDKROOT=${DIR_NDK} TARGET=android-16 ARCH=arm PREFIX=${DIR_SYSROOT} clean \
    >> ${LOG_FILE} 2>&1
printf "    done\n    "
# mekame edited - END


# Build FFmpeg.
printf "FFMPEG\n"
export PATH=${ORIGINAL_PATH}:${DIR_SYSROOT}/bin
cd ${DIR_NDK}/sources/ffmpeg \
    >> ${LOG_FILE} 2>&1

if [ "$1" = "--reset" ] || [ "$1" = "--init" ]; then
    printf "    resetting\n"
    git checkout -- . \
        >> ${LOG_FILE} 2>&1
    git checkout release/n3.3.3 \
        >> ${LOG_FILE} 2>&1
    git pull \
        >> ${LOG_FILE} 2>&1
fi

printf "    cleaning\n"
make clean \
    >> ${LOG_FILE} 2>&1 || true

printf "    configuring\n"
# mekame edited - START
./configure \
    --prefix=${DIR_SYSROOT} --arch=${CPU} --target-os=linux \
    --extra-ldflags="-L${DIR_SYSROOT}/lib ${PIE_FLAGS}" \
    --extra-cflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
    --extra-cxxflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
    --enable-cross-compile --cross-prefix=${PREFIX}- --sysroot=${DIR_SYSROOT} \
    --disable-gpl --disable-nonfree --disable-shared --enable-static --disable-doc --enable-ffprobe --disable-ffserver \
    --disable-version3 --enable-swscale-alpha \
    --enable-libvpx \
    --enable-libopenh264 \
    --enable-encoder=libvpx \
    --enable-encoder=libvpx-v9 \
    --enable-encoder=libopenh264 \
    --disable-encoder=h261 \
    --disable-encoder=h263 \
    --disable-encoder=h263i \
    --disable-encoder=h263p \
    --disable-encoder=h264 \
    --disable-encoder=hevc \
    --disable-decoder=h261 \
    --disable-decoder=h263 \
    --disable-decoder=h263i \
    --disable-decoder=h263p \
    --disable-decoder=h264 \
    --disable-decoder=hevc \
    $enablePic \
        >> ${LOG_FILE} 2>&1
# mekame edited - END

#./configure \
#    --prefix=${DIR_SYSROOT} --arch=${CPU} --target-os=linux \
#    --extra-ldflags="-L${DIR_SYSROOT}/lib ${PIE_FLAGS}" \
#    --extra-cflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
#    --extra-cxxflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
#    --enable-cross-compile --cross-prefix=${PREFIX}- --sysroot=${DIR_SYSROOT} \
#    --disable-gpl --disable-nonfree --disable-shared --enable-static --disable-doc --enable-ffprobe --disable-ffserver \
#    --enable-libvorbis --disable-version3 --enable-libvpx --enable-swscale-alpha \
#    --disable-encoders \
#    --enable-encoder=apng \
#    --enable-encoder=ayuv \
#    --enable-encoder=huffyuv \
#    --enable-encoder=rawvideo \
#    --enable-encoder=v210 \
#    --enable-encoder=v308 \
#    --enable-encoder=v408 \
#    --enable-encoder=v410 \
#    --enable-encoder=libvpx \
#    --enable-encoder=libvpx-v9 \
#    --enable-encoder=wrapped_avframe \
#    --enable-encoder=y41p \
#    --enable-encoder=yuv4 \
#    --enable-encoder=pcm_f32be \
#    --enable-encoder=pcm_f32le \
#    --enable-encoder=pcm_s16be \
#    --enable-encoder=pcm_s16le \
#    --enable-encoder=pcm_s24be \
#    --enable-encoder=pcm_s24le \
#    --enable-encoder=pcm_s32be \
#    --enable-encoder=pcm_s32le \
#    --enable-encoder=pcm_u16be \
#    --enable-encoder=pcm_u16le \
#    --enable-encoder=pcm_u24be \
#    --enable-encoder=pcm_u24le \
#    --enable-encoder=pcm_u32be \
#    --enable-encoder=pcm_u32le \
#    --enable-encoder=vorbis \
#    --enable-encoder=wavpack \
#    --disable-decoder=h261 \
#    --disable-decoder=h263 \
#    --disable-decoder=h263i \
#    --disable-decoder=h263p \
#    --disable-decoder=h264 \
#    --disable-decoder=hevc \
#    $enablePic \
#        >> ${LOG_FILE} 2>&1

printf "    building\n"
make -j${NUM_JOBS} \
    >> ${LOG_FILE} 2>&1

printf "    installing\n"
make install \
    >> ${LOG_FILE} 2>&1

printf "    done\n    "
ls ${DIR_SYSROOT}/bin | grep ffmpeg
export PATH=${ORIGINAL_PATH}

# Copy executable to output directory.
mkdir -p $ffmpegOutputDir \
    >> ${LOG_FILE} 2>&1
cp ${DIR_SYSROOT}/bin/ffmpeg $ffmpegOutputDir \
    >> ${LOG_FILE} 2>&1
printf "Android ffmpeg executable in ${ffmpegOutputDir}/\n\0"

./move_pie.sh
