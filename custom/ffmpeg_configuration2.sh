./configure \
    --prefix=${DIR_SYSROOT} --arch=${CPU} --target-os=linux \
    --extra-ldflags="-L${DIR_SYSROOT}/lib ${PIE_FLAGS}" \
    --extra-cflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
    --extra-cxxflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
    --enable-cross-compile --cross-prefix=${PREFIX}- --sysroot=${DIR_SYSROOT} \
    --disable-gpl --disable-nonfree --disable-shared --enable-static --disable-doc \
    --disable-all --enable-ffmpeg \
    --enable-avcodec --enable-avformat --enable-avutil --enable-swresample --enable-avfilter --enable-swscale \
    --enable-filter=aresample --enable-filter=crop --enable-filter=scale --enable-filter=transpose \
    --enable-protocol=file \
    --enable-libvorbis --enable-libvpx \
    --enable-decoder=aac --enable-decoder=amrnb --enable-decoder=amrwb --enable-decoder=flac --enable-decoder=mp3 --enable-decoder=libvorbis --enable-decoder=adpcm_ima_wav \
    --enable-decoder=h263 --enable-decoder=h263p --enable-decoder=h264 --enable-decoder=mpeg4 --enable-decoder=libvpx_vp8 \
    --enable-demuxer=concat \
    --enable-demuxer=mov --enable-demuxer=mpegts --enable-demuxer=webm --enable-demuxer=matroska \
    --enable-encoder=libvorbis \
    --enable-encoder=libvpx_vp8 \
    --enable-muxer=webm \
    $enablePic \
