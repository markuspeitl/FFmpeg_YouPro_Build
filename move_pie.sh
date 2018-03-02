sharedPath='/media/sf_stuffshare/';
printf $sharedPath"\n";

uuid=$(uuidgen);
printf $uuid"\n";

newDirPath=$sharedPath$uuid;
mkdir $newDirPath;
printf $newDirPath"\n";

cp -f build_ffmpeg.sh $newDirPath/build_ffmpeg.sh
cp -f $DIR_NDK/bin/arm/pie/ffmpeg $newDirPath/ffmpeg

printf "Moved ffmpeg to shared folder";

platformpath=$DIR_NDK'platforms/android-16/arch-arm';

cp -f $platformpath/usr/lib/libopenh264.so $newDirPath/libopenh264.so

printf "Moved libopneh264.so to shared folder";
