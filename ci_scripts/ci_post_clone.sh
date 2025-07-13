#!/bin/sh

#  ci_post_clone.sh
#  Task Steps
#
#  Created by 遠藤拓弥 on 2024/03/30.
#  Updated for Task Steps project

# Xcode マクロフィンガープリント検証をスキップ
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES

echo "Post clone setup completed for Task Steps"
