Slightly modified FFmpeg build scripts for Android from https://github.com/Yelp/ffmpeg-android.<br />
Building was tested under Ubuntu 17.<br />
The following commands refer to bash commands from the ubuntu terminal.<br /><br />

## 1. <br />
(Option 1) Download android NDK (https://developer.android.com/ndk/downloads/index.html) or <br />
(Option 2) comment in corresponding section (line 33-53) in build_ffmpeg.sh and <br />
download it together with the other sources when executing later down the line <br />
<br />
```
$ ./build_ffmpeg.sh --init
```
<br />
(My suggestion is to download the NDK manually (Option 1), as we can easier test multiple different NDK version and do not have to worry if the Evironment variable for the NDK
Path is correctly set from the script)
<br /><br />
## 2.<br />
(Option 1)<br />
Change into your cloned Git - Directory with:<br />
<br />
```
cd<br />
cd $pathToYourGitDir
```
<br /><br />
Export the NDK Path environment variable to use it in the scripts:
<br />
```
export DIR_NDK=$pathToYouNdkDirectory
```
<br />
(Option 2)<br />
Nothing to do here. Should be set automatically from the script if everything goes as intended.
<br />
## 3<br />
(Option 1|Option 2)<br />
Call to download additional sources: <br />
<br />
```
$ ./build_ffmpeg.sh --init
```
<br />
## 4<br />
(Option 1|Option 2)<br />
Build your own FFmpeg configuration if you want.<br />
Look at the examples that are provided in FFmpeg_YouPro_Build\custom that are named like following "ffmpeg_configuration.sh" and 
use this or create your own.
<br /><br />
Then copy its contents and replace the configuration part in build_ffmpeg.sh at line 325 to have FFmpeg build with a different or you custom configuration.
<br /><br />
## 5<br />
### 5.1<br />
(Option 1|Option 2)<br />
Build FFmpeg when the newest sources are not checked out yet for the use in android by calling:<br />
<br />
```
./build_ffmpeg_arm_pie.sh --reset
```
<br />
<br />
### 5.2<br />
(Option 1|Option 2)<br />
If you have all the sources downloaded and just want to rebuild or rebuild with a different configuration just call:<br />
<br />
```
./build_ffmpeg_arm_pie.sh
```
<br /><br />
## 6<br />
Check $pathToYouNdkDirectory/bin for your libraries and copy them before resuming if you want to build FFmpeg in other configuration.<br />
I suggest to always copy the configuration of FFmpeg you used as a file together with the built binary, so you can look up the configuration when you need it (which is likely at some point).<br />
<br /><br />

# What to do if building fails for some reason?<br />
<br />
## 1<br />
Try diffenrent versions of the android NDK.<br />
When trying to build FFmpeg myself, i experienced not being able to build FFmpeg with some versions of the NDK <br />
(Newest versions are often not supported yet, older versions sometimes conflict with new librarys a bit (i think or assume)).<br />
<br />
## 2<br />
Sometimes the source version seem to conflict with each other.<br />
To fix this i suggest first dowloading the libraries via script and then replacing the contents of the folder for specified library with the contents of the manually downlaoded library sources.<br />
For Instance:<br />
1. Finish steps (1)-(5.1).<br />
2. Download FFmpeg sources in desired version from github.<br />
3. Copy source files from the downloaded version into existing $pathToYouNdkDirectory/sources/FFmpeg folder and replace existing files<br />
4. Build with Step (5.2) <br />
<br />
## 3<br />
Check if download links for additional libraries in "build_ffmpeg.sh" are active and up, otherwise the download or extraction will fail.<br />
If link is not active anymore search the internet for an active or new version of the library and replace the link in the script.<br />
Then try it out if all works correctly.<br />
<br /><br />

(Know any other issues and fixxes? Let me know and i will add them to the list!)
<br /><br />

Original Readme:<br />

```
FFMPEG build scripts for Android. Tested on OS X 10.9.4.

For more information about FFmpeg, see https://www.ffmpeg.org/download.html#get-sources.

## How to to build

* Install [autotools](http://www.jattcode.com/installing-autoconf-automake-libtool-on-mac-osx-mountain-lion/) (or just run ./autotools.sh).
* Clone the repo.
* Define where you want NDK installed. DONT use any symbolic links in `$DIR_NDK`.

        $ cd yelp-ffmpeg4android
        $ export DIR_NDK=$(pwd)/ndk

#### Download sources

This will download the sources and generate the toolchain.

    $ ./build_ffmpeg.sh --init

#### Build for the first time

 This will checkout certain library branches and build everything.

    $ ./build_ffmpeg_x86.sh --reset
    $ ./build_ffmpeg_arm.sh --reset

#### Build after changes

This will perform a clean build assuming you have the sources and the toolchain.

    $ ./build_ffmpeg_x86.sh
    $ ./build_ffmpeg_arm.sh

## Output

Check `$DIR_NDK/bin` for executables.
```