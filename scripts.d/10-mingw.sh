#!/bin/bash

MINGW_REPO="https://github.com/mirror/mingw-w64.git"
MINGW_COMMIT="a95307f5b065799b39fab72ca656eeaaa4deaf99"

ffbuild_enabled() {
    [[ $TARGET == win* ]] || return -1
    return 0
}

ffbuild_dockerlayer() {
    to_df "COPY --from=${SELFLAYER} /opt/mingw/. /"
    to_df "COPY --from=${SELFLAYER} /opt/mingw/. /opt/mingw"
}

ffbuild_dockerfinal() {
    to_df "COPY --from=${PREVLAYER} /opt/mingw/. /"
}

ffbuild_dockerbuild() {
    git-mini-clone "$MINGW_REPO" "$MINGW_COMMIT" mingw
    cd mingw

    cd mingw-w64-headers

    unset CFLAGS
    unset CXXFLAGS
    unset LDFLAGS
    unset PKG_CONFIG_LIBDIR

    GCC_SYSROOT="$(${FFBUILD_CROSS_PREFIX}gcc -print-sysroot)"

    local myconf=(
        --prefix="$GCC_SYSROOT/usr/$FFBUILD_TOOLCHAIN"
        --host="$FFBUILD_TOOLCHAIN"
        --with-default-win32-winnt="0x601"
        --enable-idl
    )

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install DESTDIR="/opt/mingw"

    cd ../mingw-w64-libraries/winpthreads

    local myconf=(
        --prefix="$GCC_SYSROOT/usr/$FFBUILD_TOOLCHAIN"
        --host="$FFBUILD_TOOLCHAIN"
        --with-pic
        --disable-shared
        --enable-static
    )

    ./configure "${myconf[@]}"
    make -j$(nproc)
    make install DESTDIR="/opt/mingw"
}

ffbuild_configure() {
    echo --disable-w32threads --enable-pthreads
}
