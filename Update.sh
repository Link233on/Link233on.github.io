#!/bin/bash

set -e
# set -x

cd "$(dirname "$0")"

DEB_DIR="./debs"

if [ ! -d "$DEB_DIR" ]; then
  echo "Error: Directory $DEB_DIR does not exist."
  exit 1
fi

# ls -lh "$DEB_DIR"

echo "删除旧版Packages"
rm -f Packages Packages.*

echo "扫描生成并压缩Packages"
dpkg-scanpackages --multiversion "$DEB_DIR" >> Packages

cat Packages | xz > Packages.xz
cat Packages | bzip2 > Packages.bz2
cat Packages | zstd > Packages.zst

echo "生成Release文件"
apt-ftparchive \
-o APT::FTPArchive::Release::Origin="Link Repo" \
-o APT::FTPArchive::Release::Label="Link Repo" \
-o APT::FTPArchive::Release::Suite="stable" \
-o APT::FTPArchive::Release::Version="1.0" \
-o APT::FTPArchive::Release::Codename="Link233on" \
-o APT::FTPArchive::Release::Architectures="iphoneos-arm iphoneos-arm64 iphoneos-arm64e" \
-o APT::FTPArchive::Release::Components="main" \
-o APT::FTPArchive::Release::Description="Link233on opens the repository for sharing" \
release . > Release

# echo "推送提交"
# git add .
# git commit -s -m "sync repo"
# git push
