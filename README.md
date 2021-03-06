全景图片的预处理。

### Mipmap

Core concept:

![](http://upload.wikimedia.org/wikipedia/commons/5/5c/MipMap_Example_STS101.jpg)

Ours:

> Original image size: 8192 x 4096

| level |  geometry |      filesize | subimage geometry            |
| :---: | :------------: | :------: | :--------------------------: |
| L0 | `[ 8192 x 4096 ]` | ~18.65MB | `[512 x 512]`  (about 180KB) |
| L1 | `[ 4096 x 2048 ]` | ~ 4.48MB | `[512 x 512]`                |
| L2 | `[ 2048 x 1024 ]` | ~ 1.18MB | `[512 x 512]`                |
| L3 | `[ 1024 x  512 ]` | ~339.0KB | `[512 x 512]`                |
| L4 | `[  512 x  256 ]` | ~ 98.6KB | `[ -1 x  -1]`                |
| L5 | `[  256 x  128 ]` | ~ 29.8KB | `[ -1 x  -1]`                |
| L6 | `[  128 x   64 ]` | ~  9.7KB | `[ -1 x  -1]`                |

![And Now a Touch of Magick](http://www.imagemagick.org/image/wizard.jpg)

Use [ImageMagick](http://www.imagemagick.org/Usage/ "老牌神器、跨平台、脚本运行，也可调用 C 接口") to process images:

```shell
# miamapping
$ convert libpano-L0.jpg -resize 50% libpano-L1.jpg
$ convert libpano-L1.jpg -resize 50% libpano-L2.jpg
$ convert libpano-L2.jpg -resize 50% libpano-L3.jpg
$ convert libpano-L3.jpg -resize 50% libpano-L4.jpg
$ convert libpano-L4.jpg -resize 50% libpano-L5.jpg
$ convert libpano-L5.jpg -resize 50% libpano-L6.jpg

# identify
$ identify *.jpg
libpano-L0.jpg    JPEG 8192x4096 8192x4096+0+0 8-bit DirectClass 18.65MB 0.000u 0:00.000
libpano-L1.jpg[1] JPEG 4096x2048 4096x2048+0+0 8-bit DirectClass 4.487MB 0.000u 0:00.000
libpano-L2.jpg[2] JPEG 2048x1024 2048x1024+0+0 8-bit DirectClass 1.182MB 0.000u 0:00.000
libpano-L3.jpg[3] JPEG 1024x 512 1024x 512+0+0 8-bit DirectClass   339KB 0.000u 0:00.000
libpano-L4.jpg[4] JPEG  512x 256  512x 256+0+0 8-bit DirectClass  98.6KB 0.000u 0:00.000
libpano-L5.jpg[5] JPEG  256x 128  256x 128+0+0 8-bit DirectClass  29.8KB 0.000u 0:00.000
libpano-L6.jpg[6] JPEG  128x  64  128x  64+0+0 8-bit DirectClass  9.76KB 0.000u 0:00.000

# cropping
$ convert libpano-L0.jpg -crop 512x512  +repage  +adjoin  libpano-L0-%d.jpg
$ convert libpano-L1.jpg -crop 512x512  +repage  +adjoin  libpano-L1-%d.jpg
$ convert libpano-L2.jpg -crop 512x512  +repage  +adjoin  libpano-L2-%d.jpg
$ convert libpano-L3.jpg -crop 512x512  +repage  +adjoin  libpano-L3-%d.jpg

# upload
for i in *.jpg; do mongofiles -d imgs put $i; done

# number of L0 subimages 
$ ls *L0-* | wc -l
128 # for generating metadata
```

### Metadata for frontend using

0. siteinfo => img-url
0. `/gridfs/libpano.jpg` ==> img-cropping-mode
0. `/info/mode/0`

`info/mode/0`
```json
{
  "mode": "default", // 规则切片
  "levels": [
    128, // "-L0-%d", 0~127
    32,  // "-L1-%d", 0~31
    8,   // "-L2-%d", 0~7
    2,   // "-L3-%d", 0~1
    0,   // "-L4"
    0,   // "-L5"
    0    // "-L6"
  ]
}
```

mode default in detail:

* filename: '*<orginal file basename>*-L**%d**\[-**%d**\].<orginal file extension>' (no zero padding (?pros&cons of no padding)) 
* examples:
    + original filename: `libpano.jpg`
    + `libpano-L0-1.jpg`
    + `libpano-L2-23.jpg`
    + `libpano-L4.jpg`

**更新**

最不清晰的层次也应该有 4x2 个切图，而不是整张，不然效果太差。:broken_heart:

**TODO**

* 切图应当集中在低纬度区域
* ？或许不加载就可以，切图还是正方着切

切图策略：(用 L0 表示最清晰，L1 其次。。。L9 表示最不清晰层次(当然不一定有 10=9+1 层))

0. 初始化，L9 层要全加载
0. 延迟加载从 L9 扩散到 L0
0. 扩散到屏幕边缘多一点(用 fov 和大致的宽高比衡量)，进行 Level 变化
0. 每个 Level 分为三部分界限为 i. Level Up ii. 停止扩散

### 修正后的方案 :star:

* 512x512 ==> 256x256
* resizing ==> tiling ==> uploading ==> cleaning

See ImageMagick 脚本: [gen.sh](gen.sh)


### Snippets

ImageMagick

```shell
$ identify -format "%[fx:w] x %[fx:h]" libpano-L0.jpg
8192 x 4096
```

mongofiles

```shell
for i in **/;
do
    cd $i
    for j in *.jpg
    do
        # echo $j
        mongofiles -d imgs put $j
    done
    cd ..
done
```

### May be useful

* [GraphicsMagick Core C API](http://www.graphicsmagick.org/api/api.html)
