#!/bin/bash

# Wazuh package builder
# Copyright (C) 2015-2019, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

set -exf
# Optional package release
build_target=$1
wazuh_version=$2
architecture_target=$3
threads=$4
package_release=$5
directory_base=$6
debug=$7
checksum=$8
src=$9

disable_debug_flag='%debug_package %{nil}'

if [ -z "${package_release}" ]; then
    package_release="1"
fi

if [ "${debug}" = "no" ]; then
    echo ${disable_debug_flag} > /etc/rpm/macros
fi

# Build directories
build_dir=/build_wazuh
rpm_build_dir=${build_dir}/rpmbuild
file_name="wazuh-${build_target}-${wazuh_version}-${package_release}"
rpm_file="${file_name}.${architecture_target}.rpm"
src_file="${file_name}.src.rpm"
pkg_path="${rpm_build_dir}/RPMS/${architecture_target}"
src_path="${rpm_build_dir}/SRPMS"
extract_path="${src_path}"
mkdir -p ${rpm_build_dir}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Generating source tar.gz
package_name=wazuh-${build_target}-${wazuh_version}
cd ${build_dir} && tar czf "${rpm_build_dir}/SOURCES/${package_name}.tar.gz" "${package_name}"

# Including spec file
mv ${build_dir}/wazuh.spec ${rpm_build_dir}/SPECS/${package_name}.spec

if [ "${architecture_target}" = "i386" ]; then
    linux="linux32"
fi

# Building RPM
$linux rpmbuild --define "_topdir ${rpm_build_dir}" --define "_threads ${threads}" \
        --define "_release ${package_release}" --define "_localstatedir ${directory_base}" \
        --define "_debugenabled ${debug}" --target ${architecture_target} \
        -ba ${rpm_build_dir}/SPECS/${package_name}.spec

if [[ "${checksum}" == "yes" ]]; then
    cd ${pkg_path} && sha512sum ${rpm_file} > /var/local/checksum/${rpm_file}.sha512
    cd ${src_path} && sha512sum ${src_file} > /var/local/checksum/${src_file}.sha512
fi

if [[ "${src}" == "yes" ]]; then
    extract_path="${rpm_build_dir}"
fi

find ${extract_path} -maxdepth 3 -type f -name "${file_name}*" -exec mv {} /var/local/wazuh \;
