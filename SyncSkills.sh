#!/bin/bash

: << 'EOF_2026_0701_174908'

#H[skill管理][
	#H[主目錄][
		`.agents/skills/`
	]
	#H[從github Tsinswreng/ 下clone新skill 到 `TsinswrengSkills/`][
		以 `tsinswreng-stop-on-doubt` 爲例
		```sh
		cd TsinswrengSkills
		# 在Github/Tsinswreng中 所有skill倉庫都以 `skill-` 開頭、clone到本地上要把`skill-`替換成 `tsinswreng-`
		git clone https://github.com/Tsinswreng/skill-stop-on-doubt.git  tsinswreng-stop-on-doubt
		```
	]

	#H[將`TsinswrengSkills`中的skill同步到主目錄][
以 `tsinswreng-stop-on-doubt` 爲例
```sh
#pwd在項目根目錄
mkdir -p .agents/skills
cp -r TsinswrengSkills/tsinswreng-csharp-code-doc/tsinswreng-csharp-code-doc .agents/skills/tsinswreng-csharp-code-doc
```
	]

	#H[雲端同步skill內容][
以 `tsinswreng-stop-on-doubt` 爲例
```sh
cd TsinswrengSkills/tsinswreng-stop-on-doubt
git pull
```

然後再執行一遍上面將`TsinswrengSkills`中的skill同步到主目錄的步驟
	]

	#H[將主目錄中的skill同步到claude路徑的skill][
		見 `SyncLocalSkills.sh`
		```sh
mkdir -p .claude/skills
cp -r .agents/skills/* .claude/skills/
		```
	]


	#H[自動化sh腳本][
		寫個sh腳本
		格式`sh <腳本名> <skill名>`
		其中的skill名不需要`tsinswreng-`或`skill-`前綴
		之後、
		在TsinswrengSkills下面看有沒有這個skill的git倉庫。
		如果沒有就去clone 如果有了就git pull同步。
		然後把TsinswrengSkills下面的skill同步到.agent/skills/主目錄。

		如果傳入的參數沒給skill名 那就把 `TsinswrengSkills/`下的所有git倉庫都pull再同步到主目錄。
	]

]


EOF_2026_0701_174908

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_REPO_DIR="$SCRIPT_DIR/TsinswrengSkills"
AGENTS_SKILLS_DIR="$SCRIPT_DIR/.agents/skills"
GITHUB_BASE_URL="https://github.com/Tsinswreng"

# $1: skill short name (no prefix), e.g. "csharp-code-doc"
sync_one_skill() {
    local skill_name="$1"
    local repo_dir="$SKILLS_REPO_DIR/tsinswreng-$skill_name"
    local repo_url="$GITHUB_BASE_URL/skill-$skill_name.git"

    if [ -d "$repo_dir" ]; then
        echo "[pull] tsinswreng-$skill_name"
        git -C "$repo_dir" pull
    else
        echo "[clone] tsinswreng-$skill_name <- $repo_url"
        git clone "$repo_url" "$repo_dir"
    fi

    # Copy skill content to .agents/skills/
    local src="$repo_dir/tsinswreng-$skill_name"
    local dst="$AGENTS_SKILLS_DIR/tsinswreng-$skill_name"

    if [ -d "$src" ]; then
        mkdir -p "$AGENTS_SKILLS_DIR"
        echo "[sync] $src -> $dst"
        rm -rf "$dst"
        cp -r "$src" "$dst"
    else
        echo "[warn] skill inner directory not found: $src, skipping copy"
    fi
}

mkdir -p "$SKILLS_REPO_DIR"

if [ $# -ge 1 ]; then
    # Single skill mode
    sync_one_skill "$1"
else
    # All skills mode: pull and sync every repo under TsinswrengSkills/
    echo "[sync-all] pulling and syncing all skills in $SKILLS_REPO_DIR"

    found_any=false
    for repo_dir in "$SKILLS_REPO_DIR"/*/; do
        [ -d "$repo_dir" ] || continue

        repo_name="$(basename "$repo_dir")"
        # Skip if not a tsinswreng- prefixed dir or no .git
        [ -d "$repo_dir/.git" ] || continue
        [[ "$repo_name" == tsinswreng-* ]] || continue

        echo "[pull] $repo_name"
        git -C "$repo_dir" pull || echo "[warn] pull failed for $repo_name, continuing..."

        src="$repo_dir/$repo_name"
        dst="$AGENTS_SKILLS_DIR/$repo_name"

        if [ -d "$src" ]; then
            mkdir -p "$AGENTS_SKILLS_DIR"
            echo "[sync] $src -> $dst"
            rm -rf "$dst"
            cp -r "$src" "$dst"
        else
            echo "[warn] skill inner directory not found: $src, skipping copy"
        fi

        found_any=true
    done

    if ! $found_any; then
        echo "[warn] no skill repos found in $SKILLS_REPO_DIR"
    fi
fi

echo "[done]"
