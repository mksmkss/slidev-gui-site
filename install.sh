#!/bin/sh
# Slidev GUI を Mac に入れる（紹介のページの 1 行から呼ばれる）。
#   curl -fsSL https://mksmkss.github.io/slidev-gui-site/install.sh | sh
# すること: 配布物（zip）とその SHA-256 を取り、照合してから「アプリケーション」に置く。ほかの場所は触らない。
# 変数の直後に全角の文字が続くところは ${VAR} と書く（sh が変数名を読み違えて止まる）。
# 管理者の権限（sudo）は使わない。/Applications に書けないときは ~/Applications に置く。
set -eu

REPO="mksmkss/slidev-gui-site"
APP="Slidev GUI.app"
BASE="https://github.com/$REPO/releases/latest/download"

say() { printf '%s\n' "$*"; }
die() {
  say "中止しました: $*" >&2
  exit 1
}

[ "$(uname -s)" = "Darwin" ] || die "このスクリプトは macOS 用です（Windows 版はまだありません）"
case "$(uname -m)" in
  arm64) ARCH="arm64" ;;
  x86_64) ARCH="x64" ;;
  *) die "この Mac の種類（$(uname -m)）には対応していません" ;;
esac
ZIP="slidev-gui-$ARCH-mac.zip"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/slidev-gui-install.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT INT TERM

say "Slidev GUI（${ARCH}）を取ってきます…"
curl -fL --proto '=https' --tlsv1.2 --progress-bar -o "$TMP/$ZIP" "$BASE/$ZIP" ||
  die "ダウンロードできませんでした（$BASE/${ZIP}）"
curl -fsSL --proto '=https' --tlsv1.2 -o "$TMP/SHA256SUMS" "$BASE/SHA256SUMS" ||
  die "照合用のファイルを取れませんでした"

WANT="$(awk -v f="$ZIP" '$2 == f { print $1 }' "$TMP/SHA256SUMS")"
GOT="$(shasum -a 256 "$TMP/$ZIP" | awk '{ print $1 }')"
[ -n "$WANT" ] || die "照合用のファイルに $ZIP がありません"
[ "$WANT" = "$GOT" ] || die "ファイルが壊れているか、書き換えられています（SHA-256 が合いません）"

ditto -x -k "$TMP/$ZIP" "$TMP/out"
[ -d "$TMP/out/$APP" ] || die "配布物の中にアプリがありません"

DEST="/Applications"
if [ ! -w "$DEST" ]; then
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
fi

if pgrep -f "$DEST/$APP/Contents/MacOS/" >/dev/null 2>&1; then
  die "Slidev GUI が開いています。終了してから、もう一度実行してください"
fi

# 前の版があれば置き換える（設定とスライドのファイルは別の場所にあるので消えない）
if [ -e "$DEST/$APP" ]; then
  mv "$DEST/$APP" "$TMP/old.app"
fi
mv "$TMP/out/$APP" "$DEST/$APP"

say "入れました: $DEST/$APP"
say "開くには: open \"$DEST/$APP\""
