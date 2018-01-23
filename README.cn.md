# bor
一个可定制的给图片加边框的脚本

(English version please see [here](README.md))

我的博客上常常会发一些自己拍的照片[haozhexu.me](https://haozhexu.me)，有时需要显示照片的拍摄参数，这个脚本便是用来给照片加边框，同时可以定制显示拍摄参数，以及定制照片的尺寸和质量压缩。

早年间为了避免指纹，照片的相纸会刻意留出白框，而拿到相片的人往往会在空白处写下拍摄日期及地点等信息。后来的宝丽来和富士拍立得也沿用了这一风格。

这个脚本需要用到[ImageMagic®](https://www.imagemagick.org)，如果要把EXIF信息从生成的照片里移除的话，[ExifTool](https://www.sno.phy.queensu.ca/~phil/exiftool/)也是需要的，在Mac上两者都可以用[Homebrew](https://brew.sh/)安装:

```
brew install imagemagic
brew install exiftool
```

bor.sh 是个命令行脚本，可以接收若干选项，图片文件名是必须的，生成的图片文件名若没指定，则默认为_原始文件名_bor.文件格式_。

例子：

**按指定像素缩放**

```
./bor.sh -r 800x600 photo.jpg
```

**按百分比缩放**

```
./bor.sh -r 80% photo.jpg
```

**按总像素量缩放**

缩小photo.jpg，使得总像素(长乘以宽)不超过4096。

```
./bor.sh -r 4096@ photo.jpg
```

**降低图片质量**

把photo.jpg的画质降低到80%

```
./bor.sh -q 80 photo.jpg
```

**按指定像素大小加边框**

加20x20像素的边框

```
./bor.sh -b 20x20 photo.jpg
```

**按原始相片的比例加边框**

给photo.jpg加边框，左右边框大小是相片宽的5%，上下边框大小是相片高的10%。

```
./bor.sh -b 5%x10% photo.jpg
```

**在边框上写下相片的拍摄参数(EXIF)**

加上指定的拍摄参数，中等字体大小

```
./bor.sh -b 5%x10% -e cameramodel,focallength35,fnumber,exptime,isospeed,stripexif -f medium photo.jpg
```

可选的字体大小：

* small: 20%边框大小
* medium: 30%边框大小
* large: 50%边框大小

可选的EXIF参数 (用在 -e 后，以逗号分开):

* cameramodel
* focallength35
* fnumber
* exptime
* isospeed
* stripexif - 这不是一个拍摄参数，如果指定的话，生成的相片文件不会包含原始相片的EXIF信息

**所有选项都指定的例子**

```
./bor.sh -b 5%x10% -e cameramodel,focallength35,fnumber,exptime,isospeed,stripexif -f medium -r 80% -q 70 photo.jpg photo_output.jpg
```

生成的相片：

![生成的相片](./photo_output.jpg "生成的相片")

我会持续改善这个脚本，如果有任何建议请[告诉我](mailto:haozhe.xu3@gmail.com)。
