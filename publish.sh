#!/usr/bin/env bash

depend_files=(
    "./build.sh"
    "./Makefile"
)

die () {
    echo -e "\033[0;31m[ \033[1;91mFATAL\033[0;31m ]:\033[0m $1\033[0m" >&2

    exit 1
}

for i_file in ${depend_files[@]}; do
    [[ -f "$i_file" ]] || die "Missing file: '$i_file'"
done

[[ "$OGLO_WEBSITE_PUBLISH_DIR" == "" ]] && die '$OGLO_WEBSITE_PUBLISH_DIR not set!'
[[ -d "$OGLO_WEBSITE_PUBLISH_DIR" ]] || die 'Directory specified in $OGLO_WEBSITE_PUBLISH_DIR does not exist!'

./build.sh || die "Failed to build website HTML/CSS files!"

back_path="$(pwd)"

cd "$OGLO_WEBSITE_PUBLISH_DIR"

git pull origin main || die "Failed to pull down changes before pushing!"

[[ -f ./prepare.sh ]] && ./prepare.sh || die "Failed to prepare for publishing!"

cd "$back_path"

mv ./out/* "$OGLO_WEBSITE_PUBLISH_DIR" || die "Failed to move everything!"

if [[ -d "$OGLO_WEBSITE_PUBLISH_DIR/.git" ]]; then
    while true; do
        read -p "Would you like to push new Git changes? [yes/no]: " user_answer

        break_loop=0

        if [[ "$user_answer" == "yes" ]]; then
            cd "$OGLO_WEBSITE_PUBLISH_DIR"

            git add . || die "Failed to Git add!"
            git commit -m "Publish website changes." || die "Failed to commit changes!"
            git push || die "Failed to push!"

            cd "$back_path"
            break_loop=1
        elif [[ "$user_answer" == "no" ]]; then
            echo "Okay, not pushing..."
            break_loop=1
        fi

        [[ "$break_loop" == "1" ]] && break

        echo "Invalid answer, try again..."
    done
fi
