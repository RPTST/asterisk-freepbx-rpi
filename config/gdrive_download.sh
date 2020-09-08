#!/bin/bash
# https://drive.google.com/file/d/1BzeB0yH9nPcQ2rV8RW_DyUBR5ISNhN6v/view
fileId=1BzeB0yH9nPcQ2rV8RW_DyUBR5ISNhN6v
fileName=libspandsp2_0.0.6-2.1_armhf.deb
curl -sc /tmp/cookie "https://drive.google.com/uc?export=download&id=${fileId}" > /dev/null
code="$(awk '/_warning_/ {print $NF}' /tmp/cookie)"
curl -Lb /tmp/cookie "https://drive.google.com/uc?export=download&confirm=${code}&id=${fileId}" -o ${fileName}
