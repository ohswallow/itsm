#!/bin/bash

VERSION=1.8.9
echo "기존 %USERPROFILE%\ 있는 .mix, .hex 폴더 삭제후 다운로드"
cd $USERPROFILE
rm -R $LOCALAPPDATA/elixir_make
rm -R $LOCALAPPDATA/rustler_precompiled
rm -RF .hex .mix sqe-mix
pwd
git clone http://gitlab.j2db.co.kr:8080/itsm/sqe-mix.git
cd sqe-mix
mv -f ./$VERSION/.hex $USERPROFILE
mv -f ./$VERSION/.mix $USERPROFILE
mv -f ./$VERSION/AppData/Local/elixir_make $LOCALAPPDATA
mv -f ./$VERSION/AppData/Local/rustler_precompiled $LOCALAPPDATA
cd ..
rm -RF sqe-mix
