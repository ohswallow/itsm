#! /bin/bash

echo "elixir-ls 폴더삭제"
rm -RF $LOCALAPPDATA/mix

echo "elixir-ls 파일복사중.."
cp -RF ./setting_file/mix $LOCALAPPDATA

echo "Visual Studio Code 설정파일 복사중.."
cp -RF ./setting_file/vscode_setting/. $APPDATA/CODE/USER

read -p "Vim Extension을 사용여부(Y/N)" answer
if [[ "$answer" == "Y" || "$answer" == "y" ]]; then
  cp -RF ./setting_file/vscode_vim_setting/. $APPDATA/CODE/USER
fi
