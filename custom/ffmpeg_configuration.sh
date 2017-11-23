./configure \
    --prefix=${DIR_SYSROOT} --arch=${CPU} --target-os=linux \
    --extra-ldflags="-L${DIR_SYSROOT}/lib ${PIE_FLAGS}" \
    --extra-cflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
    --extra-cxxflags="-I${DIR_SYSROOT}/include ${PIE_FLAGS}" \
    --enable-cross-compile --cross-prefix=${PREFIX}- --sysroot=${DIR_SYSROOT} \
    --disable-gpl --disable-nonfree --disable-shared --enable-static --disable-doc \
    --enable-libvorbis --enable-libvpx \
    $enablePic \
