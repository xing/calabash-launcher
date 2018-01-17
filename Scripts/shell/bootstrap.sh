#!/bin/sh

#  bootstrap.sh
#  Calabash Launcher
#
#  Created by Martin Kim Dung-Pham on 14.01.18.
#  Copyright © 2018 XING. All rights reserved.

# walk into the directory managed by Swift Package Manager
cd ${SOURCE_ROOT}/Core

# Fetch new version if available and desired by the package manifest
#swift package --disable-sandbox update

# Build so the dependencies can be used in the Calabash Launcher (via Calabash Launcher Core)
swift build --disable-sandbox

