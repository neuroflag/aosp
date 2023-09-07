#!/usr/bin/env bash
set -eux
set -o pipefail
cd $(dirname "${BASH_SOURCE[0]}")/../../../..

(cd $NEUROFLAG_MONOREPO && ./medical/hermione/build-android-app.sh)
cp -f $NEUROFLAG_MONOREPO/bazel-bin/medical/hermione/android/src/main/NeuroflagHermione.apk ./device/neuroflag/apps/NeuroflagHermione/NeuroflagHermione.apk
