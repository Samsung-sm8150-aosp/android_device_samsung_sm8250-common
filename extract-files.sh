#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

function blob_fixup() {
    case "${1}" in
    	vendor/etc/libnfc-nci.conf)
            sed -i 's/\/data\/nfc/\/data\/vendor\/nfc/g' "${2}"
            ;;
    esac

    case "${2}" in
        vendor/lib/hw/audio.primary.kona.so)
            # Before
            # 07 ad 01 eb  # bl         __android_log_print
            # 52 b0 01 eb  # bl         send_haptic_data_to_xlog
            # After
            # 07 ad 01 eb  # bl         __android_log_print
            # 00 f0 20 e3  # nop
            sed -i 's|\x07\xad\x01\xeb\x52\xb0\x01\xeb|\x07\xad\x01\xeb\x00\xf0\x20\xe3|g' "${2}"

            # Before
            # 53 b0 01 eb  # bl         send_EarsCompensation_dailyuse_to_xlog
            # 56 b0 01 eb  # bl         send_EarsCompensation_to_xlog
            # After
            # 00 f0 20 e3  # nop
            # 00 f0 20 e3  # nop
            sed -i 's|\x53\xb0\x01\xeb\x56\xb0\x01\xeb|\x00\xf0\x20\xe3\x00\xf0\x20\xe3|g' "${2}"

            # Before
            # 04 10 a0 e1  # cpy        r1,r4
            # 57 b0 01 eb  # bl         send_music_playback_to_xlog
            # After
            # 04 10 a0 e1  # cpy        r1,r4
            # 00 f0 20 e3  # nop
            sed -i 's|\x04\x10\xa0\xe1\x57\xb0\x01\xeb|\x04\x10\xa0\xe1\x00\xf0\x20\xe3|g' "${2}"

            # Before
            # 18 10 90 e5  # ldr        r1,[r0,#0x18]
            # 58 b0 01 eb  # bl         send_misound_data_to_xlog
            # After
            # 18 10 90 e5  # ldr        r1,[r0,#0x18]
            # 00 f0 20 e3  # nop
            sed -i 's|\x18\x10\x90\xe5\x58\xb0\x01\xeb|\x18\x10\x90\xe5\x00\xf0\x20\xe3|g' "${2}"
            ;;
    esac
}

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common )
                ONLY_COMMON=true
                ;;
        --only-target )
                ONLY_TARGET=true
                ;;
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="/home/j0sh1x/projectx/m"
fi

if [ -z "${ONLY_TARGET}" ]; then
    # Initialize the helper for common device
    setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../${DEVICE}/extract-files.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

    extract "${MY_DIR}/../${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
