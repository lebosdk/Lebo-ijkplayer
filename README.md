### 乐播修改说明

- 解决特殊视频多条视频流播放失败问题

视频: https://devstreaming-cdn.apple.com/videos/wwdc/2017/703muvahj3880222/703/hls_vod_mvp.m3u8
这种多流格式在国内比较少见，国外估计比较多些，要选择哪个stream
需要考虑用户网络带宽，解码器性能等因素，一般是让用户自己选择，ijkplayer 是支持
播放过程中切换track（实验性功能）。目前先简单处理，后期再完善让用户动态选择。
当存在多条视频流时:
选择分辨率最大的流，如果分辨率相同，优先选择h264格式流。

视频分辨率大小比较等价于宽高的乘积比较。
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

- 解决在部分设备上硬解码器创建失败

原因分析：
1，ijkplayer比较保守，profile大于high就不使用mediacodec硬解码而用ffmpeg软解码，
    但是在海信PX510, 天猫魔盒M16S实测是能够支持H264 High10视频解码的。
2，avformat_find_stream_info 未获取到视频的profile导致不使用mediacodec硬解码
    而用ffmpeg软解码。
对于高分辨率（profile 大于High更加可能是高分辨率），使用软解码，会因为软解码性能不足，
出现音视频不同步，卡顿等问题。

解决方案：
创建mediacodec的时候，不对profile做判断，如果mediacodec真的不支持，会导致创建失败，
硬解码失败了再使用软解码。

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

- 解决airplay投屏视频起播画面慢问题

问题分析：
腾讯视频通过AirPlay投屏视频，启播画面慢。
h264流见PHOENIX-674 附件 tx_lb_hls.h264, 可见extradata是annex-b format
并非是AVCC format (http://aviadr1.blogspot.com/2010/05/h264-extradata-partially-explained-for.html),
这导致mediacodec mediaformat
没有配置csd-0，queueinput很多包都没有出帧，直到遇到 sps pps。

解决方案：
添加 annex-b format 的支持，并区分启始码00 00 01 和 00 00 00 01
两种格式。

/////////////////////////////////////////////////////////////////////////////////////////////////////////////

- 解决seek后起播位置不准确以及起播画面慢问题

问题分析：
audio accurate_seek start, is->seek_pos=151000000, audio_clock=156.038095, is->accurate_seek_start_time = 752949
seek_pos 的帧pts为156s, 而请求的是151s，即seek到的位置超过了请求的位置，
从日志可见，在接下来的accurate_seek_timeout(5s)，只是做sleep操作，并没有实际上的作用。
所以在这种seek的情况下导致启播画面慢。

解决问题:
1，如果seek的帧位置超过请求位置，则停止accurate_seek；
2，打印详细的日志；
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


- 解决url长度超1024字符无法播放问题

问题分析：
乐视视频推送的hls url地址存在大于1024，而ffplay会设置 ijklongurl
这个protocol (2015年提交的，原因可能当时的ffmpeg url长度最大是1024)，
造成hls在解析playlist要拼接seg base url 到 ts url 失败。

解决方案：
注释掉ijklongurl的使用，目前libavformat/internal.h
中MAX_URL_SIZE定义为4096，已经足够大了。
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

- 解决硬解码器对视频sps-pps解析兼容

问题分析：
海信电视VIDAA_TV播放部分视频素材花屏

解决方案：
同步镜像的解决方法，增加对于sps pps的处理选项 mediacodec-sps-pps-usage：
0: 仅设置CSD
1: 仅作为Frame输入
2: 既设置CSD也作为Frame输入


# ijkplayer

 Platform | Build Status
 -------- | ------------
 Android | [![Build Status](https://travis-ci.org/Bilibili/ci-ijk-ffmpeg-android.svg?branch=master)](https://travis-ci.org/Bilibili/ci-ijk-ffmpeg-android)
 iOS | [![Build Status](https://travis-ci.org/Bilibili/ci-ijk-ffmpeg-ios.svg?branch=master)](https://travis-ci.org/Bilibili/ci-ijk-ffmpeg-ios)

Video player based on [ffplay](http://ffmpeg.org)

### Download

- Android:
 - Gradle
```
# required
allprojects {
    repositories {
        jcenter()
    }
}

dependencies {
    # required, enough for most devices.
    compile 'tv.danmaku.ijk.media:ijkplayer-java:0.8.8'
    compile 'tv.danmaku.ijk.media:ijkplayer-armv7a:0.8.8'

    # Other ABIs: optional
    compile 'tv.danmaku.ijk.media:ijkplayer-armv5:0.8.8'
    compile 'tv.danmaku.ijk.media:ijkplayer-arm64:0.8.8'
    compile 'tv.danmaku.ijk.media:ijkplayer-x86:0.8.8'
    compile 'tv.danmaku.ijk.media:ijkplayer-x86_64:0.8.8'

    # ExoPlayer as IMediaPlayer: optional, experimental
    compile 'tv.danmaku.ijk.media:ijkplayer-exo:0.8.8'
}
```
- iOS
 - in coming...

### My Build Environment
- Common
 - Mac OS X 10.11.5
- Android
 - [NDK r10e](http://developer.android.com/tools/sdk/ndk/index.html)
 - Android Studio 2.1.3
 - Gradle 2.14.1
- iOS
 - Xcode 7.3 (7D175)
- [HomeBrew](http://brew.sh)
 - ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
 - brew install git

### Latest Changes
- [NEWS.md](NEWS.md)

### Features
- Common
 - remove rarely used ffmpeg components to reduce binary size [config/module-lite.sh](config/module-lite.sh)
 - workaround for some buggy online video.
- Android
 - platform: API 9~23
 - cpu: ARMv7a, ARM64v8a, x86 (ARMv5 is not tested on real devices)
 - api: [MediaPlayer-like](android/ijkplayer/ijkplayer-java/src/main/java/tv/danmaku/ijk/media/player/IMediaPlayer.java)
 - video-output: NativeWindow, OpenGL ES 2.0
 - audio-output: AudioTrack, OpenSL ES
 - hw-decoder: MediaCodec (API 16+, Android 4.1+)
 - alternative-backend: android.media.MediaPlayer, ExoPlayer
- iOS
 - platform: iOS 7.0~10.2.x
 - cpu: armv7, arm64, i386, x86_64, (armv7s is obselete)
 - api: [MediaPlayer.framework-like](ios/IJKMediaPlayer/IJKMediaPlayer/IJKMediaPlayback.h)
 - video-output: OpenGL ES 2.0
 - audio-output: AudioQueue, AudioUnit
 - hw-decoder: VideoToolbox (iOS 8+)
 - alternative-backend: AVFoundation.Framework.AVPlayer, MediaPlayer.Framework.MPMoviePlayerControlelr (obselete since iOS 8)

### NOT-ON-PLAN
- obsolete platforms (Android: API-8 and below; iOS: pre-6.0)
- obsolete cpu: ARMv5, ARMv6, MIPS (I don't even have these types of devices…)
- native subtitle render
- avfilter support

### Before Build
```
# install homebrew, git, yasm
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install git
brew install yasm

# add these lines to your ~/.bash_profile or ~/.profile
# export ANDROID_SDK=<your sdk path>
# export ANDROID_NDK=<your ndk path>

# on Cygwin (unmaintained)
# install git, make, yasm
```

- If you prefer more codec/format
```
cd config
rm module.sh
ln -s module-default.sh module.sh
cd android/contrib
# cd ios
sh compile-ffmpeg.sh clean
```

- If you prefer less codec/format for smaller binary size (include hevc function)
```
cd config
rm module.sh
ln -s module-lite-hevc.sh module.sh
cd android/contrib
# cd ios
sh compile-ffmpeg.sh clean
```

- If you prefer less codec/format for smaller binary size (by default)
```
cd config
rm module.sh
ln -s module-lite.sh module.sh
cd android/contrib
# cd ios
sh compile-ffmpeg.sh clean
```

- For Ubuntu/Debian users.
```
# choose [No] to use bash
sudo dpkg-reconfigure dash
```

- If you'd like to share your config, pull request is welcome.

### Build Android
```
git clone https://github.com/Bilibili/ijkplayer.git ijkplayer-android
cd ijkplayer-android
git checkout -B latest k0.8.8

./init-android.sh

cd android/contrib
./compile-ffmpeg.sh clean
./compile-ffmpeg.sh all

cd ..
./compile-ijk.sh all

# Android Studio:
#     Open an existing Android Studio project
#     Select android/ijkplayer/ and import
#
#     define ext block in your root build.gradle
#     ext {
#       compileSdkVersion = 23       // depending on your sdk version
#       buildToolsVersion = "23.0.0" // depending on your build tools version
#
#       targetSdkVersion = 23        // depending on your sdk version
#     }
#
# If you want to enable debugging ijkplayer(native modules) on Android Studio 2.2+: (experimental)
#     sh android/patch-debugging-with-lldb.sh armv7a
#     Install Android Studio 2.2(+)
#     Preference -> Android SDK -> SDK Tools
#     Select (LLDB, NDK, Android SDK Build-tools,Cmake) and install
#     Open an existing Android Studio project
#     Select android/ijkplayer
#     Sync Project with Gradle Files
#     Run -> Edit Configurations -> Debugger -> Symbol Directories
#     Add "ijkplayer-armv7a/.externalNativeBuild/ndkBuild/release/obj/local/armeabi-v7a" to Symbol Directories
#     Run -> Debug 'ijkplayer-example'
#     if you want to reverse patches:
#     sh patch-debugging-with-lldb.sh reverse armv7a
#
# Eclipse: (obselete)
#     File -> New -> Project -> Android Project from Existing Code
#     Select android/ and import all project
#     Import appcompat-v7
#     Import preference-v7
#
# Gradle
#     cd ijkplayer
#     gradle

```


### Build iOS
```
git clone https://github.com/Bilibili/ijkplayer.git ijkplayer-ios
cd ijkplayer-ios
git checkout -B latest k0.8.8

./init-ios.sh

cd ios
./compile-ffmpeg.sh clean
./compile-ffmpeg.sh all

# Demo
#     open ios/IJKMediaDemo/IJKMediaDemo.xcodeproj with Xcode
# 
# Import into Your own Application
#     Select your project in Xcode.
#     File -> Add Files to ... -> Select ios/IJKMediaPlayer/IJKMediaPlayer.xcodeproj
#     Select your Application's target.
#     Build Phases -> Target Dependencies -> Select IJKMediaFramework
#     Build Phases -> Link Binary with Libraries -> Add:
#         IJKMediaFramework.framework
#
#         AudioToolbox.framework
#         AVFoundation.framework
#         CoreGraphics.framework
#         CoreMedia.framework
#         CoreVideo.framework
#         libbz2.tbd
#         libz.tbd
#         MediaPlayer.framework
#         MobileCoreServices.framework
#         OpenGLES.framework
#         QuartzCore.framework
#         UIKit.framework
#         VideoToolbox.framework
#
#         ... (Maybe something else, if you get any link error)
# 
```


### Support (支持) ###
- Please do not send e-mail to me. Public technical discussion on github is preferred.
- 请尽量在 github 上公开讨论[技术问题](https://github.com/bilibili/ijkplayer/issues)，不要以邮件方式私下询问，恕不一一回复。


### License

```
Copyright © [lebo], [2024].
Based on the original work by [Bilibili], licensed under the LGPLv2.1.

```

ijkplayer required features are based on or derives from projects below:
- LGPL
  - [FFmpeg](http://git.videolan.org/?p=ffmpeg.git)
  - [libVLC](http://git.videolan.org/?p=vlc.git)
  - [kxmovie](https://github.com/kolyvan/kxmovie)
  - [soundtouch](http://www.surina.net/soundtouch/sourcecode.html)
- zlib license
  - [SDL](http://www.libsdl.org)
- BSD-style license
  - [libyuv](https://code.google.com/p/libyuv/)
- ISC license
  - [libyuv/source/x86inc.asm](https://code.google.com/p/libyuv/source/browse/trunk/source/x86inc.asm)

android/ijkplayer-exo is based on or derives from projects below:
- Apache License 2.0
  - [ExoPlayer](https://github.com/google/ExoPlayer)

android/example is based on or derives from projects below:
- GPL
  - [android-ndk-profiler](https://github.com/richq/android-ndk-profiler) (not included by default)

ios/IJKMediaDemo is based on or derives from projects below:
- Unknown license
  - [iOS7-BarcodeScanner](https://github.com/jpwiddy/iOS7-BarcodeScanner)

ijkplayer's build scripts are based on or derives from projects below:
- [gas-preprocessor](http://git.libav.org/?p=gas-preprocessor.git)
- [VideoLAN](http://git.videolan.org)
- [yixia/FFmpeg-Android](https://github.com/yixia/FFmpeg-Android)
- [kewlbear/FFmpeg-iOS-build-script](https://github.com/kewlbear/FFmpeg-iOS-build-script) 

### Commercial Use
ijkplayer is licensed under LGPLv2.1 or later, so itself is free for commercial use under LGPLv2.1 or later

But ijkplayer is also based on other different projects under various licenses, which I have no idea whether they are compatible to each other or to your product.

[IANAL](https://en.wikipedia.org/wiki/IANAL), you should always ask your lawyer for these stuffs before use it in your product.
