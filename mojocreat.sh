#!/usr/bin/env bash

project="${1:-my-mojo-project}"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0 [project-name]"
  echo "Creates a new Mojo project with pixi"
  exit 0
fi

if ! command -v pixi >/dev/null 2>&1; then
  echo "Installing pixi ..."
  curl -fsSL https://pixi.sh/install.sh | bash
fi

source ~/.bashrc

if [[ -d "$project" ]]; then
  echo "Ordner $project existiert bereits"
  exit 1
fi

echo "Creating project: $project"
pixi init "$project" -c https://conda.modular.com/max-nightly/ -c conda-forge

cd "$project" || exit 1

echo "Installing mojo ..."
pixi add mojo

echo "Mojo version:"
pixi run mojo --version

echo "Fertig. Starte mit: pixi shell"
