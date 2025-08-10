#!/usr/bin/env bash

expected_pandoc_version_major="3"

cmd_deps=(
    'pandoc'
)

die () {
    echo -e "\033[0;31m[ \033[1;91mFATAL\033[0;31m ]:\033[0m $1\033[0m" >&2

    exit 1
}

secs_since_epoch () {
    date '+%s'
}

pandoc_version () {
    pandoc --version | head --lines 1 | cut -f2 -d ' '
}

pandoc_version_major () {
    pandoc_version | cut -f1 -d '.'
}

build_begin_time=$(secs_since_epoch)

for cmd_i in ${cmd_deps[@]}; do
    command -v "$cmd_i" > /dev/null 2>&1 || die "Missing dependency: '$cmd_i'"
done

[[ "$(pandoc_version_major)" == "$expected_pandoc_version_major" ]] \
|| die "Invalid Pandoc major version! Expected $expected_pandoc_version_major, found $(pandoc_version_major)!"

[[ -f ./src/index.md ]] || die "Must be run in project root!"

cd ./src || die "Failed to enter source directory!"

if [[ -d ../out ]] then
    rm -rf ../out || die "Failed to remove old 'out' directory!"
fi

echo -e "\n\033[1;93mBuilding...\033[0m\n"

while IFS= read -r md_file; do
    if [[ "$(basename "$md_file")" == "README.md" ]]; then
        continue
    fi

    html_file="$(echo "$md_file" | sed 's/.md$/.html/')"

    md_parent_dir="$(echo "$md_file" | sed "s/\/$(basename "$md_file")\$//")"

    if [[ "$html_file" == "./"* ]]; then
        html_file="../out/$(echo "$html_file" | sed 's/^.\///')"
    else
        html_file="out/${html_file}"
    fi

    html_parent_dir="$(echo "$html_file" | sed "s/\/$(basename "$html_file")\$//")"

    per_html_dir="${html_parent_dir}/PER_HTML"

    web_title="$(echo "$html_file" | sed 's/^..\///;s/\\/\//g;s/^out\///;s/\//>/g')"
    web_title="OgloTheNerd's Website (${web_title})"

    page_build_begin=$(secs_since_epoch)

    echo -en "  \033[0;96m$md_file\033[0m \033[0;36m->\033[0m \033[0;96m$html_file\033[0m"

    dest_dir="$(echo "$html_file" | sed "s/$(basename "$html_file")\$//")"

    [[ -d "$dest_dir" ]] || mkdir -p "$dest_dir" || die "Failed to create directory!"

    cp -r ./PER_HTML "$per_html_dir" || die "Failed to copy over per HTML stuff!"

    pandoc -f markdown -t html5 -c ./PER_HTML/style.css -s -H ./PANDOC/header.html --metadata "title=$web_title" -o "$html_file" "$md_file" || die "Failed to convert file: '$md_file'"

    extra_files_dir="${md_parent_dir}/EXTRA_FILES"
    extra_files_dir_target="${html_parent_dir}/EXTRA_FILES"

    if [[ -d "$extra_files_dir" ]]; then
        cp -r "$extra_files_dir" "$extra_files_dir_target"
    fi

    page_build_end=$(secs_since_epoch)
    page_build_duration=$(( ${page_build_end} - ${page_build_begin} ))

    echo -e " \033[0;93m...\033[0m \033[0;32m[\033[0m \033[1;92m${page_build_duration} seconds\033[0m \033[0;32m]\033[0m"
done < <(find . | grep -E ".md$")

build_end_time=$(secs_since_epoch)
build_duration=$(( ${build_end_time} - ${build_begin_time} ))

echo -e "\n\033[1;92mBuild took ${build_duration} seconds.\033[0m\n"
