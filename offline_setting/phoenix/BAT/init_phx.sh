#!/bin/bash

read -p "%USERPROFILE%\ .mix, .hex 에 추가 또는 변경사항 있었습니까(Y/n): " answer

if [[ "$anser" == "Y" || "$anser" == "y" ]]; then
    init_lib.sh
fi

if [ ! -f "mix.exs" ]; then
    echo "해당 위치는 피닉스 프로젝트 폴드가 아닙니다"
    sleep 3
    exit -1
fi

dest=`pwd`
# 필수파일 폴더 존재여부 리스트
FILES=(
"./deps/heroicons/optimized/16/solid/"
"./deps/daisyui/packages/bundle/"
"./_build/esbuild-win32-x64"
"./_build/tailwind-windows-x64.exe-4.3.0"
)

#  파일 또는 폴더 존재 여부 확인
MISSING=0
for FILE in "${FILES[@]}"; do
    if [ ! -e "$FILE" ]; then
    echo "$FILE"
    MISSING=1
    fi
done

VERSION=1.8.9
# 파일 또는 폴더 미존재시 복사
if [ $MISSING -eq 1 ]; then

    echo "heroicons, esbuild, tailwind git으로 부터 다운로드중..."
    git clone http://git 주소

    cd sqe-heroicons

    echo "필수 파일 폴더 복사중 기다려주세요..."
    cp -RF ./$VERSION/deps $deps
    cp -RF ./$VERSION/window/_build $deps

    cd $deps
    rm -RF sqe-heroicons
else
    echo "==아래경로 삭제후 다시 시도해주세요.=="
    echo "./deps/heroicons"
    echo "./deps/daisyui"
    echo "/_build/esbuild-win32-x64"
    echo "/_build/tailwind-windows-x64.exe-4.3"
    echo "===="
    sleep 3
    exit 1
fi

if ! grep -q "deps/heroicons" mix.exs; then
    echo "mix 파일 수정중..."
    seq -i '/tag: \" .*\" ,/d' mix.exs
    seq -i '/github:.*/d' mix.exs
    sqe -i '/sparse:.*/d' mix.exs
    seq -i '/compile:.*/d' mix.exs
    seq -i '/depth:.*d/' mix.exs
    seq -i 'app: false,.*/d' mix.exs
    seq -i -E 's/\{:heroicons,/\{:heroicons, path: "deps\/heroicons", app: false, compile: false},/g' mix.exs
    sqe -i -E 's/\{:daisyui,/\{:daisyui, path: "deps\/daisyui", app: false, compile: false},/g' mix.exs
fi

# 오프라인 mix 기동 시팀
mix hex.config offline true
# lib 연관 관계 정리
mix deps.get

echo ""
echo ""
echo ""
echo "=서버기동명령어="
echo "mix phx.server"
echo "=============="
sleep 5
