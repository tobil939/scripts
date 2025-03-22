#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: ./tex.sh <datei.tex>"
  exit 1
fi

tex_file=$1

rm -rf out/*
rm -rf pdf/*
mkdir -p out
mkdir -p pdf

if [ ! -f "$tex_file" ]; then
  echo "Error: Datei $tex_file existiert nicht."
  exit 1
fi

lualatex "$tex_file"
pdflatex "$tex_file"

pdf_file="${tex_file%.tex}.pdf"
aux_file="${tex_file%.tex}.aux"
dvi_file="${tex_file%.tex}.dvi"
log_file="${tex_file%.tex}.log"
out_file="${tex_file%.tex}.out"
toc_file="${tex_file%.tex}.toc"
nav_file="${tex_file%.tex}.nav"
snm_file="${tex_file%.tex}.snm"

if [ -f "$pdf_file" ]; then
  if [ -d "pdf" ]; then
    mv "$pdf_file" pdf/
    echo "PDF wurde erfolgreich nach 'pdf' verschoben: pdf/$pdf_file"
  else
    echo "Error: Der Ordner 'pdf' existiert nicht."
    exit 1
  fi
else
  echo "Error: PDF-Datei $pdf_file wurde nicht erstellt."
  exit 1
fi

for file in "$aux_file" "$dvi_file" "$log_file" "$out_file" "$toc_file" "$nav_file" "$snm_file"; do
  if [ -f "$file" ]; then
    mv "$file" out/
    echo "Datei $file wurde nach 'out' verschoben."
  else
    echo "Warnung: Datei $file wurde nicht gefunden."
  fi
done
