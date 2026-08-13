#!/bin/bash

echo "=== Cấu hình Bitbucket cho swift-ads package ==="
echo ""

# Lưu token vào Keychain
git credential-osxkeychain store <<EOF
protocol=https
host=bitbucket.org
username=DucManh98
password=ATATT3xFfGF0thzi3xcAWj1cG5q7oP17ZH-h4swuQLeEp6OIVkFK7lnkr6C7UnBZx9576xGL8xM1AEpwX9fQG9rS8_c5wALnNLgRswtiEAjPp7Cv1l3R72C0-Oc28Iix8MUcAaQarX8lN8_s1UCgu_Z3ZCjx089E3RbupgiNOb0ihOSnoEdC9Vg=002EC9C9
EOF

echo "Token da duoc luu vao Keychain."
echo ""
echo "=== QUAN TRONG ==="
echo "Neu Xcode co account Bitbucket Cloud cu:"
echo "  1. Mo Xcode -> Settings (Cmd + ,) -> Accounts"
echo "  2. Chon Bitbucket Cloud -> bam dau '-' de xoa"
echo ""
echo "Sau do trong Xcode:"
echo "  File -> Add Package Dependencies"
echo "  Dan URL: https://bitbucket.org/innofyapp/swift-ads.git"
echo ""
echo "=== Hoan tat ==="
