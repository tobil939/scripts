#!/usr/bin/env bash

file="$1"
oldpath=$(pwd)
filepath=$(dirname "$file")

if [[ -z "$file" ]]; then
  echo "Usage: $0 datei.mojo"
  exit 1
fi

if [[ ! -f "$file" ]]; then
  echo "Datei nicht gefunden: $file"
  exit 1
fi

base=$(basename "$file" .mojo)
pyfile="${filepath}/${base}.py"

echo "→ erstelle $pyfile (rudimentäre Übersetzung)"

echo "#!/usr/bin/env python3" >"$pyfile"
sed '
  s/^fn /def /g
  s/ -> /) -> /g
  s/ -> None:/):/
  s/var //g
  s/let //g
  s/inout //g
  s/borrowed //g
  s/struct /class /g
  s/trait /# trait (nicht direkt übersetzbar)/g
  s/SIMD\[[^]]*\]/# SIMD → numpy.array o.ä./g
  s/parallelize(/# parallelize → multiprocessing o.ä./g
' "$file" >>"$pyfile"
sed -i '/^$/d' "$pyfile"

echo 'if __name__ == "__main__": main()' >>"$pyfile"

chmod +x "$pyfile"

echo "going into $filepath"
cd "$filepath" || exit 1

echo "→ kompiliere $file"

pixi run mojo build "$(basename "$file")" -o "$base"

echo "going into $oldpath"
cd "$oldpath" || exit 1

if [[ -x "${filepath}/${base}" ]]; then
  echo "→ Binary: ${filepath}/${base}"
  echo "→ Python: $pyfile"
else
  echo "Fehler beim Kompilieren"
  exit 2
fi
