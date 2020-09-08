#!/bin/bash
# https://drive.google.com/file/d/1n0-2kgsV5jYYedZIc62r3ys3CYafkg52/view
fileId=1n0-2kgsV5jYYedZIc62r3ys3CYafkg52
fileName=freepbx-14.0-latest.tgz
curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${fileId}" > /dev/null
code="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"
curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${code}&id=${fileId}" -o ${fileName}
