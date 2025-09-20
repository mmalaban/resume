# MMalabanan Resume/CV

## Installation requirements

```bash
texlive-latex texlive-collection-basic
```

## Dependencies

A list of dependencies:

- fontenc
- inputenc
- textcomp
- fontawesome5
- sourceserifpro
- hyperref
- url
- geometry
- xparse
- xfp
- pgffor
- enumitem

Script is provided to install the necesary dependencies for this LaTeX project.

### Usage of script

To use the script, at root folder use the following command:

```bash
./scripts/dependencies.sh mmalabanan-cv.tex
```

For dry-run:

```bash
./scripts/dependencies.sh mmalabanan-cv.tex --dry-run
```

### Description of the script

- Parses `\usepackage{}` commands from your LaTeX file
- Uses `dnf` for package management on Fedora
- Maps LaTeX packages to Fedora packages automatically
- Asks for confirmation before installing each package
- Installs one by one with individual confirmations
- Shows dry-run option with `--dry-run` flag
- Logs everything to a timestamped log file
- Checks additional tools like `biber`, `latexmk`, etc.

## Creating the resume/cv pdf

```bash
pdflatex mmalabanan-cv.tex
```

> **NOTE**: All code shown is executed on Fedora 42, adjust accordingly depending on you OS.
