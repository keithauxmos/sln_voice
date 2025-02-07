#!/bin/bash
set -e

XCORE_VOICE_ROOT=`git rev-parse --show-toplevel`

source ${XCORE_VOICE_ROOT}/tools/ci/helper_functions.sh

# setup distribution folder
DIST_DIR=${XCORE_VOICE_ROOT}/dist
DIST_HOST_DIR=${XCORE_VOICE_ROOT}/dist_host
mkdir -p ${DIST_DIR}

if [ -d "${DIST_HOST_DIR}" ]; then
    # add DIST_HOST_DIR to path.
    #   This is used in CI for fatfs_mkimage
    PATH="${DIST_HOST_DIR}":$PATH
    find ${DIST_HOST_DIR} -type f -exec chmod a+x {} +
fi

# setup configurations
# row format is: "name app_target fs_target flag BOARD toolchain"
examples=(
    "ffd_usb_audio   example_ffd_usb_audio_test   example_ffd    NONE   XK_VOICE_L71   xmos_cmake_toolchain/xs3a.cmake"
    #"ffd_usb_audio_bypass_ap   example_ffd_usb_audio_test_bypass_ap   example_ffd   NONE   XK_VOICE_L71   xmos_cmake_toolchain/xs3a.cmake"
    "stlp_ua_adec   example_stlp_ua_adec   example_stlp_ua_adec   DEBUG_STLP_USB_MIC_INPUT   XK_VOICE_L71   xmos_cmake_toolchain/xs3a.cmake"
    #"stlp_ua_adec_altarch   example_stlp_ua_adec_altarch   example_stlp_ua_adec DEBUG_STLP_USB_MIC_INPUT   XK_VOICE_L71   xmos_cmake_toolchain/xs3a.cmake"
    "stlp_sample_rate_conv   example_stlp_ua_adec   example_stlp_ua_adec   DEBUG_STLP_USB_MIC_INPUT_PIPELINE_BYPASS   XK_VOICE_L71   xmos_cmake_toolchain/xs3a.cmake"
)

# perform builds
for ((i = 0; i < ${#examples[@]}; i += 1)); do
    read -ra FIELDS <<< ${examples[i]}
    name="${FIELDS[0]}"
    app_target="${FIELDS[1]}"
    fs_target="${FIELDS[2]}"

    flag="${FIELDS[3]}"
    board="${FIELDS[4]}"
    toolchain_file="${XCORE_VOICE_ROOT}/${FIELDS[5]}"
    path="${XCORE_VOICE_ROOT}"
    echo '******************************************************'
    echo '* Building' ${name}, ${app_target} 'for' ${board}
    echo '******************************************************'

    if [ "${flag}" = "NONE" ]; then
        optional_cache_entry=""
    else
        optional_cache_entry="-D${flag}=1"
    fi

    (cd ${path}; rm -rf build_${board})
    (cd ${path}; mkdir -p build_${board})
    (cd ${path}/build_${board}; log_errors cmake ../ -DCMAKE_TOOLCHAIN_FILE=${toolchain_file} -DBOARD=${board} -DENABLE_ALL_STLP_PIPELINES=1 ${optional_cache_entry}; log_errors make ${app_target} -j)
    (cd ${path}/build_${board}; cp ${app_target}.xe ${DIST_DIR}/example_${name}_test.xe)
    if [ "${fs_target}" != "NONE" ]; then
        if [ ! -f ${DIST_DIR}/${fs_target}_fat.fs ]; then
            # need to make the filesystem file for the fs_target
            #  this is getnerate once per fs_target and later copied 
            #  to match the name of the app_target.  
            echo '======================================================'
            echo '= Making filesystem for' ${fs_target}
            echo '======================================================'
            (cd ${path}/build_${board}; log_errors make make_fs_${fs_target} -j)
            (cd ${path}/build_${board}; cp ${fs_target}_fat.fs ${DIST_DIR}/${fs_target}_fat.fs)
        fi
    fi    
done
