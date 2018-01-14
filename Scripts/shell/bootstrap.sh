#!/bin/sh

#  bootstrap.sh
#  Calabash Launcher
#
#  Created by Martin Kim Dung-Pham on 14.01.18.
#  Copyright © 2018 XING. All rights reserved.

cd ./Core
swift package update
swift package generate-xcodeproj
