#!/bin/bash
# https://drive.google.com/file/d/1inyoSuM8GLKner9BBoAxmYsFM59v0LuF/view
fileId=1inyoSuM8GLKner9BBoAxmYsFM59v0LuF
fileName=asterisk-15.7.2.tar.gz
curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${fileId}" > /dev/null
code="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"
curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${code}&id=${fileId}" -o ${fileName}
