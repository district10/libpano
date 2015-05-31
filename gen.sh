#!/bin/bash

# remove from db first
#        $ mongo
#        > use imgs
#        switched to db imgs
#        > db.fs.files.remove({filename: /panolib/})
#        WriteResult({ "nRemoved" : 1368 })

cp ~/Downloads/panolib.jpg ./
IMG=$(basename panolib.jpg)
img="${IMG%.*}"
ext="${IMG##*.}"
echo Processing img: ${img}, ext: ${ext}

#                                          Main    Layers
mv      $IMG                              ${img}-L0.${ext}
convert ${img}-L0.${ext} -resize 50%      ${img}-L1.${ext}
convert ${img}-L1.${ext} -resize 50%      ${img}-L2.${ext}
convert ${img}-L0.${ext} -resize 1024x512 ${img}-L3.${ext}

# sub images
convert ${img}-L0.${ext} -crop 256x256  +repage  +adjoin  ${img}-L0-%d.${ext}
convert ${img}-L1.${ext} -crop 256x256  +repage  +adjoin  ${img}-L1-%d.${ext}
convert ${img}-L2.${ext} -crop 256x256  +repage  +adjoin  ${img}-L2-%d.${ext}
convert ${img}-L3.${ext} -crop 256x256  +repage  +adjoin  ${img}-L3-%d.${ext}

# put into mongodb
for i in *${ext};
do
    mongofiles -d imgs put $i # > /dev/null
done

# statistics
echo A little statistics
echo \#L0: $(ls *-L0-* | wc -l)
echo \#L1: $(ls *-L1-* | wc -l)
echo \#L2: $(ls *-L2-* | wc -l)
echo \#L3: $(ls *-L3-* | wc -l)
: '
#L0: 512
#L1: 128
#L2: 32
#L3: 8
'

# then, delete all of them
rm *.${ext} -f
