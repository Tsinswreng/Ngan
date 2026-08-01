#!/usr/bin/env bash
set -e
Tag=$1
[[ -z $Tag ]] && { echo "用法: $0 <tag>"; exit 1; }



sh ./TagLibs.sh $Tag
sh ./TagEtPushRepo.sh  Ngan.Dict.Core  $Tag
sh ./TagEtPushRepo.sh  Ngan.Dict.Backend  $Tag
sh ./TagEtPushRepo.sh  Ngan.Dict.Frontend  $Tag
sh ./TagEtPushRepo.sh  Ngan.Dict.Server  $Tag
sh ./TagEtPushRepo.sh  Ngan.Dict.Test  $Tag



# 主项目打 tag
git tag -a "$Tag" -m "$Tag"
#git push origin "$Tag"
