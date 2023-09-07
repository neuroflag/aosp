#!/usr/bin/env bash
set -eux
set -o pipefail
cd $(dirname "${BASH_SOURCE[0]}")/../../../..

(cd $NEUROFLAG_MONOREPO && bazel build --config=android-arm64 //medical/ron/driver/server:ron-driver-server)
cp -f $NEUROFLAG_MONOREPO/bazel-bin/medical/ron/driver/server/ron-driver-server ./device/neuroflag/apps/ron-driver/prebuilt/arm64-v8a/ron-driver-server
(cd $NEUROFLAG_MONOREPO && bazel build --config=android-arm64 //medical/ron/driver/client:ron-driver-client)
cp -f $NEUROFLAG_MONOREPO/bazel-bin/medical/ron/driver/client/ron-driver-client ./device/neuroflag/apps/ron-driver/prebuilt/arm64-v8a/ron-driver-client
