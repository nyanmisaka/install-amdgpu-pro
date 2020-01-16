#!/bin/bash
# Made by Andrew Shark, The author of LinuxComp Tutorial Youtube channel

# To install amdgpu-pro on ubuntu 19.04 we want to use the following:
# ./amdgpu-install --pro --opencl=lagacy,pal
# But there are several problems in 19.50-855429 release:
# 1-19.10-785425) amdgpu-dkms fails to build in 19.10 (probably could be fixed, I did not explored it yet). I checked that this driver actually works without dkms version of amdgpu kernel modules, so solution is omitting it.
# 1-19.50-855429) There is no such problem, it builds ok, so we can ignore problem 3
# 2) amdgpu-core checks ubuntu version before installation and refuses to continue if ubuntu version is not 18.04. Solution is to remove this check. It is in preinst script.
# 3) amdgpu-pro(-hwe) and amdgpu-pro-lib32 depends on amdgpu(-hwe), however they should depend on amdgpu-lib(-hwe) instead. amdgpu(-hwe) itself depends on amdgpu-dkms and amdgpu-lib(-hwe). Because of this issue, amdgpu-dkms package is still in installation list when we use --no-dkms. So solution is to modify depends array of amdgpu-pro(-hwe) and amdgpu-pro-lib32. Or just use a fake empty amdgpu-dkms package.
# 4) Then we need to edit packages hashsums and filesizes of modified packages in Packages file and hashsums of Packages file in Release file.
# 5) And we need to edit amdgpu-install script to use hwe packages (they are more recent versions of non-hwe ones).
# After that we could install amdgpu-pro 19.50-855429 in ubuntu 19.04.
# Ok, lets start!

# remove installation if it was done previously
if [ -f uninstall-force.sh ]; then
    bash uninstall-force.sh
fi

major=19.50
minor=967956

# Solving problem 1:
# There is no problem currently.
# But we will not install amdgpu-dkms, because we will skip most of the open components installation.

# Solving problem 2:
# removing checking ubuntu version
DEBFILE=amdgpu-core_"$major"-"$minor"_all.deb
TMPDIR=`mktemp -d /tmp/deb.XXXXXXXXXX` || exit 1
OUTPUT=`basename "$DEBFILE" .deb`.no_ub_ver_chk.deb
dpkg-deb -x "$DEBFILE" "$TMPDIR"
dpkg-deb --control "$DEBFILE" "$TMPDIR"/DEBIAN
rm "$TMPDIR"/DEBIAN/preinst
rm -f $OUTPUT # remove modded deb if already exist
dpkg -b "$TMPDIR" "$OUTPUT"
rm -r "$TMPDIR"

# for some reason hashsum is different after every build. Not explored why yet. So I will get it in this script dinamically
ag_core_mod_md5=$(md5sum $OUTPUT | cut -f1 -d" ")
ag_core_mod_sha1=$(sha1sum $OUTPUT | cut -f1 -d" ")
ag_core_mod_sha256=$(sha256sum $OUTPUT | cut -f1 -d" ")
ag_core_mod_size=$(wc -c < $OUTPUT)


# Solving problem 3:
# # making fake amdgpu-dkms
# rm -rf amdgpu-dkms-fake
# mkdir -p amdgpu-dkms-fake/DEBIAN
# echo -e "
# Package: amdgpu-dkms
# Version: $major-$minor
# Architecture: all
# Maintainer: Unreal Person <you@email.com>
# Section: misc
# Priority: optional
# Description: Fake empty package to workaround amdgpu-pro stack dependcy on dkms" > amdgpu-dkms-fake/DEBIAN/control
# dpkg-deb --build amdgpu-dkms-fake
# rm -rf amdgpu-dkms-fake
# 
# ag_dkms_mod_md5=$(md5sum amdgpu-dkms-fake.deb | cut -f1 -d" ")
# ag_dkms_mod_sha1=$(sha1sum amdgpu-dkms-fake.deb | cut -f1 -d" ")
# ag_dkms_mod_sha256=$(sha256sum amdgpu-dkms-fake.deb | cut -f1 -d" ")
# ag_dkms_mod_size=$(wc -c < amdgpu-dkms-fake.deb)


# Making modded amdgpu-pro-hwe for avoiding installation of amdgpu-hwe
rm -rf amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep
mkdir -p amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep/DEBIAN
echo -e "
Package: amdgpu-pro-hwe
Version: $major-$minor
Architecture: amd64
Maintainer: Unreal Person <you@email.com>
Installed-Size: 17
Depends: amdgpu-pro-core (= 19.50-967956), libgl1-amdgpu-pro-glx (= 19.50-967956), libegl1-amdgpu-pro (= 19.50-967956), libgles2-amdgpu-pro (= 19.50-967956), libglapi1-amdgpu-pro (= 19.50-967956), libgl1-amdgpu-pro-ext-hwe (= 19.50-967956), libgl1-amdgpu-pro-dri (= 19.50-967956), libgl1-amdgpu-pro-appprofiles (= 19.50-967956), libgbm1-amdgpu-pro (= 19.50-967956), libgbm1-amdgpu-pro-base (= 19.50-967956)
Section: metapackages
Priority: optional
Description: Removed dependency on amdgpu-hwe to avoid installation of most open components" > amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep/DEBIAN/control
dpkg-deb --build amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep
rm -rf amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep

ag_prohwe_mod_md5=$(md5sum amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep.deb | cut -f1 -d" ")
ag_prohwe_mod_sha1=$(sha1sum amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep.deb | cut -f1 -d" ")
ag_prohwe_mod_sha256=$(sha256sum amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep.deb | cut -f1 -d" ")
ag_prohwe_mod_size=$(wc -c < amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep.deb)

# # Making modded amdgpu-pro-hwe:i386 for avoiding installation of amdgpu-hwe:i386
# rm -rf amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep
# mkdir -p amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep/DEBIAN
# echo -e "
# Package: amdgpu-pro-hwe
# Version: $major-$minor
# Architecture: i386
# Maintainer: Unreal Person <you@email.com>
# Installed-Size: 17
# Depends: amdgpu-pro-core (= 19.50-967956), libgl1-amdgpu-pro-glx (= 19.50-967956), libegl1-amdgpu-pro (= 19.50-967956), libgles2-amdgpu-pro (= 19.50-967956), libglapi1-amdgpu-pro (= 19.50-967956), libgl1-amdgpu-pro-ext-hwe (= 19.50-967956), libgl1-amdgpu-pro-dri (= 19.50-967956), libgl1-amdgpu-pro-appprofiles (= 19.50-967956), libgbm1-amdgpu-pro (= 19.50-967956), libgbm1-amdgpu-pro-base (= 19.50-967956)
# Section: metapackages
# Priority: optional
# Description: Removed dependency on amdgpu-hwe:i386 to avoid installation of most open components" > amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep/DEBIAN/control
# dpkg-deb --build amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep
# rm -rf amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep
# 
# ag_prohwe32_mod_md5=$(md5sum amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep.deb | cut -f1 -d" ")
# ag_prohwe32_mod_sha1=$(sha1sum amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep.deb | cut -f1 -d" ")
# ag_prohwe32_mod_sha256=$(sha256sum amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep.deb | cut -f1 -d" ")
# ag_prohwe32_mod_size=$(wc -c < amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep.deb)


# Making modded amdgpu-pro-lib32 for skipping of installation of ag|ag-hwe and amdgpu-lib32
rm -rf amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep
mkdir -p amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep/DEBIAN
echo -e "
Package: amdgpu-pro-lib32
Version: $major-$minor
Architecture: amd64
Maintainer: Unreal Person <you@email.com>
Installed-Size: 17
Depends: amdgpu-pro (= 19.50-967956) | amdgpu-pro-hwe (= 19.50-967956), libgl1-amdgpu-pro-glx:i386 (= 19.50-967956), libegl1-amdgpu-pro:i386 (= 19.50-967956), libgles2-amdgpu-pro:i386 (= 19.50-967956), libglapi1-amdgpu-pro:i386 (= 19.50-967956), libgl1-amdgpu-pro-dri:i386 (= 19.50-967956), libgbm1-amdgpu-pro:i386 (= 19.50-967956)
Priority: optional
Description: Removed dependency on ag|ag-hwe and amdgpu-lib32 to avoid installation of most open components" > amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep/DEBIAN/control
dpkg-deb --build amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep
rm -rf amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep

ag_prolib32_mod_md5=$(md5sum amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep.deb | cut -f1 -d" ")
ag_prolib32_mod_sha1=$(sha1sum amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep.deb | cut -f1 -d" ")
ag_prolib32_mod_sha256=$(sha256sum amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep.deb | cut -f1 -d" ")
ag_prolib32_mod_size=$(wc -c < amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep.deb)


# Solving problem 4:
# filling new checksums to Packages and Release

# for ag-core:
sed -i "36{s/.*/Filename: .\/amdgpu-core_"$major"-"$minor"_all.no_ub_ver_chk.deb/}" Packages
sed -i "37{s/.*/Size: $ag_core_mod_size/}" Packages
sed -i "38{s/.*/MD5sum: $ag_core_mod_md5/}" Packages
sed -i "39{s/.*/SHA1: $ag_core_mod_sha1/}" Packages
sed -i "40{s/.*/SHA256: $ag_core_mod_sha256/}" Packages
# # for ag-dkms:
# sed -i "51{s/.*/Depends: amdgpu-doc/}" Packages
# sed -i "52{s/.*/Filename: .\/amdgpu-dkms-fake.deb/}" Packages
# sed -i "53{s/.*/Size: $ag_dkms_mod_size/}" Packages
# sed -i "54{s/.*/MD5sum: $ag_dkms_mod_md5/}" Packages
# sed -i "55{s/.*/SHA1: $ag_dkms_mod_sha1/}" Packages
# sed -i "56{s/.*/SHA256: $ag_dkms_mod_sha256/}" Packages


# for ag-pro-hwe:
sed -i "252{s/.*/Depends: amdgpu-pro-core (= 19.50-967956), libgl1-amdgpu-pro-glx (= 19.50-967956), libegl1-amdgpu-pro (= 19.50-967956), libgles2-amdgpu-pro (= 19.50-967956), libglapi1-amdgpu-pro (= 19.50-967956), libgl1-amdgpu-pro-ext-hwe (= 19.50-967956), libgl1-amdgpu-pro-dri (= 19.50-967956), libgl1-amdgpu-pro-appprofiles (= 19.50-967956), libgbm1-amdgpu-pro (= 19.50-967956), libgbm1-amdgpu-pro-base (= 19.50-967956)/}" Packages # Its needed to also replace Depends in Packages.
sed -i "253{s/.*/Filename: .\/amdgpu-pro-hwe_"$major"-"$minor"_amd64.no_ag-hwe_dep.deb/}" Packages
sed -i "254{s/.*/Size: $ag_prohwe_mod_size/}" Packages
sed -i "255{s/.*/MD5sum: $ag_prohwe_mod_md5/}" Packages
sed -i "256{s/.*/SHA1: $ag_prohwe_mod_sha1/}" Packages
sed -i "257{s/.*/SHA256: $ag_prohwe_mod_sha256/}" Packages

# # for ag-pro-hwe:i386:
# sed -i "237{s/.*/Depends: amdgpu-pro-core (= 19.50-967956), libgl1-amdgpu-pro-glx (= 19.50-967956), libegl1-amdgpu-pro (= 19.50-967956), libgles2-amdgpu-pro (= 19.50-967956), libglapi1-amdgpu-pro (= 19.50-967956), libgl1-amdgpu-pro-ext-hwe (= 19.50-967956), libgl1-amdgpu-pro-dri (= 19.50-967956), libgl1-amdgpu-pro-appprofiles (= 19.50-967956), libgbm1-amdgpu-pro (= 19.50-967956), libgbm1-amdgpu-pro-base (= 19.50-967956)/}" Packages # Its needed to also replace Depends in Packages.
# sed -i "238{s/.*/Filename: .\/amdgpu-pro-hwe_"$major"-"$minor"_i386.no_ag-hwe_dep.deb/}" Packages
# sed -i "239{s/.*/Size: $ag_prohwe32_mod_size/}" Packages
# sed -i "240{s/.*/MD5sum: $ag_prohwe32_mod_md5/}" Packages
# sed -i "241{s/.*/SHA1: $ag_prohwe32_mod_sha1/}" Packages
# sed -i "242{s/.*/SHA256: $ag_prohwe32_mod_sha256/}" Packages

# for ag-pro-lib32:
sed -i "268{s/.*/Depends: amdgpu-pro (= 19.50-967956) | amdgpu-pro-hwe (= 19.50-967956), libgl1-amdgpu-pro-glx:i386 (= 19.50-967956), libegl1-amdgpu-pro:i386 (= 19.50-967956), libgles2-amdgpu-pro:i386 (= 19.50-967956), libglapi1-amdgpu-pro:i386 (= 19.50-967956), libgl1-amdgpu-pro-dri:i386 (= 19.50-967956), libgbm1-amdgpu-pro:i386 (= 19.50-967956)/}" Packages # Its needed to also replace Depends in Packages.
sed -i "269{s/.*/Filename: .\/amdgpu-pro-lib32_"$major"-"$minor"_amd64.no_ag-hwe_and_ag-lib32_dep.deb/}" Packages
sed -i "270{s/.*/Size: $ag_prolib32_mod_size/}" Packages
sed -i "271{s/.*/MD5sum: $ag_prolib32_mod_md5/}" Packages
sed -i "272{s/.*/SHA1: $ag_prolib32_mod_sha1/}" Packages
sed -i "273{s/.*/SHA256: $ag_prolib32_mod_sha256/}" Packages

packages_mod_sha256=$(sha256sum Packages | cut -f1 -d" ")
packages_mod_size=$(wc -c < Packages)

echo -e "Date: `date -R -u`
SHA256:
 $packages_mod_sha256 $packages_mod_size Packages" > Release

# Solving problem 5:
# choose hwe variant in amdgpu-install script
sed -i '147{s/^\t/#/}' amdgpu-install # commenting out this condition: if dpkg -s "xserver-xorg-hwe-18.04"
sed -i '151{s/^\t/#/}' amdgpu-install # and its closing fi


# Finally, we are ready to install:
# ./amdgpu-install --pro --opencl=legacy,pal --no-dkms
echo "Creating local repository..."
./amdgpu-install --assume-no &> /dev/null
echo -e "\e[32mInstalling OpenGL PRO...\e[0m"
sudo apt install amdgpu-pro-hwe amdgpu-pro-lib32 --assume-yes
echo -e "\e[32mInstalling OpenCL PRO...\e[0m"
# opencl-amdgpu-pro metapackage does not handle opencl-orca-amdgpu-pro-icd:i386 and depends on dkms, so I just pointed to packages manually
sudo apt install clinfo-amdgpu-pro opencl-orca-amdgpu-pro-icd opencl-orca-amdgpu-pro-icd:i386 opencl-amdgpu-pro-icd --assume-yes
# I do not know about new packages opencl-amdgpu-{comgr, hip}, roct.
echo -e "\e[32mInstalling Vulkan PRO...\e[0m"
sudo apt install vulkan-amdgpu-pro vulkan-amdgpu-pro:i386 --assume-yes
echo -e "\e[32mAll done, enjoy!\nThis script was prepared for you by Andrew Shark, the author of LinuxComp Tutorial youtube channel. If you liked it, please let me know =)\e[0m"
