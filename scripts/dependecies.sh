#!/bin/bash

# LaTeX Dependency Installer for Fedora
# Usage: ./latex-deps.sh [options] <latex-file.tex>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script options
DRY_RUN=false
VERBOSE=false
LOG_FILE="latex-deps-$(date +%Y%m%d_%H%M%S).log"

# Package mapping: LaTeX package -> Fedora package
declare -A PACKAGE_MAP=(
    # Core packages (usually already installed)
    ["fontenc"]="texlive-base"
    ["inputenc"]="texlive-base"
    ["textcomp"]="texlive-base"
    ["geometry"]="texlive-geometry"
    ["hyperref"]="texlive-hyperref"
    ["url"]="texlive-url"
    ["xparse"]="texlive-l3packages"
    ["xfp"]="texlive-l3packages"
    ["enumitem"]="texlive-enumitem"
    
    # Font packages
    ["fontawesome5"]="texlive-fontawesome5"
    ["fontawesome"]="texlive-fontawesome"
    ["sourceserifpro"]="texlive-sourceserifpro"
    ["times"]="texlive-times"
    ["helvet"]="texlive-helvet"
    ["courier"]="texlive-courier"
    
    # Graphics and drawing
    ["graphicx"]="texlive-graphics"
    ["pgf"]="texlive-pgf"
    ["pgffor"]="texlive-pgf"
    ["tikz"]="texlive-pgf"
    ["xcolor"]="texlive-xcolor"
    
    # Math packages
    ["amsmath"]="texlive-amsmath"
    ["amssymb"]="texlive-amsfonts"
    ["amsfonts"]="texlive-amsfonts"
    ["mathtools"]="texlive-mathtools"
    
    # Bibliography
    ["biblatex"]="texlive-biblatex"
    ["natbib"]="texlive-natbib"
    
    # Tables and lists
    ["array"]="texlive-array"
    ["tabularx"]="texlive-tabularx"
    ["longtable"]="texlive-longtable"
    ["booktabs"]="texlive-booktabs"
    
    # Other common packages
    ["microtype"]="texlive-microtype"
    ["babel"]="texlive-babel"
    ["csquotes"]="texlive-csquotes"
    ["fancyhdr"]="texlive-fancyhdr"
    ["setspace"]="texlive-setspace"
    ["parskip"]="texlive-parskip"
    ["indentfirst"]="texlive-indentfirst"
)

# Additional tools to check
LATEX_TOOLS=(
    "pdflatex:texlive-latex"
    "xelatex:texlive-xetex"
    "lualatex:texlive-luatex"
    "bibtex:texlive-bibtex"
    "biber:biber"
    "latexmk:texlive-latexmk"
    "makeindex:texlive-makeindex"
)

usage() {
    echo "Usage: $0 [options] <latex-file.tex>"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run     Show what would be installed without installing"
    echo "  -v, --verbose     Show detailed output"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 resume.tex"
    echo "  $0 --dry-run thesis.tex"
    echo "  $0 -v document.tex"
}

log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[LOG]${NC} $message"
    fi
}

error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" >&2
    log "ERROR: $message"
    exit 1
}

success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    log "SUCCESS: $message"
}

warning() {
    local message="$1"
    echo -e "${YELLOW}[WARNING]${NC} $message"
    log "WARNING: $message"
}

info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
    log "INFO: $message"
}

check_prerequisites() {
    info "Checking prerequisites..."
    
    # Check if running on Fedora
    if ! grep -q "^ID=fedora" /etc/os-release 2>/dev/null; then
        warning "This script is designed for Fedora. It may not work on other distributions."
    fi
    
    # Check if dnf is available
    if ! command -v dnf &> /dev/null; then
        error "dnf package manager not found. This script requires dnf."
    fi
    
    # Check if kpsewhich is available
    if ! command -v kpsewhich &> /dev/null; then
        warning "kpsewhich not found. Installing texlive-kpathsea..."
        if [ "$DRY_RUN" = false ]; then
            sudo dnf install -y texlive-kpathsea
        fi
    fi
}

parse_latex_packages() {
    local tex_file="$1"
    local packages=()
    
    info "Parsing LaTeX packages from $tex_file..."
    
    if [ ! -f "$tex_file" ]; then
        error "File $tex_file not found."
    fi
    
    # Extract packages from \usepackage commands
    # Handle both \usepackage{pkg} and \usepackage[options]{pkg}
    while IFS= read -r line; do
        if [[ $line =~ \\usepackage(\[[^]]*\])?\{([^}]+)\} ]]; then
            local pkg_list="${BASH_REMATCH[2]}"
            # Handle multiple packages in one command: \usepackage{pkg1,pkg2,pkg3}
            IFS=',' read -ra PKGS <<< "$pkg_list"
            for pkg in "${PKGS[@]}"; do
                # Trim whitespace
                pkg=$(echo "$pkg" | xargs)
                if [ -n "$pkg" ]; then
                    packages+=("$pkg")
                fi
            done
        fi
    done < "$tex_file"
    
    # Remove duplicates and sort
    printf '%s\n' "${packages[@]}" | sort -u
}

check_package_installed() {
    local latex_pkg="$1"
    
    # First try to find the .sty file
    if kpsewhich "${latex_pkg}.sty" &>/dev/null; then
        return 0
    fi
    
    # For some packages, try .cls files
    if kpsewhich "${latex_pkg}.cls" &>/dev/null; then
        return 0
    fi
    
    return 1
}

get_fedora_package() {
    local latex_pkg="$1"
    
    # Check our mapping first
    if [ -n "${PACKAGE_MAP[$latex_pkg]}" ]; then
        echo "${PACKAGE_MAP[$latex_pkg]}"
        return 0
    fi
    
    # Try common patterns
    local candidates=(
        "texlive-$latex_pkg"
        "texlive-collection-$latex_pkg"
        "$latex_pkg"
    )
    
    for candidate in "${candidates[@]}"; do
        if dnf list available "$candidate" &>/dev/null; then
            echo "$candidate"
            return 0
        fi
    done
    
    return 1
}

install_package() {
    local fedora_pkg="$1"
    local latex_pkg="$2"
    
    info "Installing $fedora_pkg for LaTeX package '$latex_pkg'..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] Would install: $fedora_pkg"
        return 0
    fi
    
    if sudo dnf install -y "$fedora_pkg" 2>/dev/null; then
        success "Installed $fedora_pkg"
        log "INSTALLED: $fedora_pkg (for $latex_pkg)"
        return 0
    else
        warning "Failed to install $fedora_pkg"
        log "FAILED: $fedora_pkg (for $latex_pkg)"
        return 1
    fi
}

check_latex_tools() {
    info "Checking LaTeX tools..."
    
    for tool_entry in "${LATEX_TOOLS[@]}"; do
        IFS=':' read -r tool package <<< "$tool_entry"
        
        if ! command -v "$tool" &>/dev/null; then
            warning "Tool '$tool' not found"
            
            echo -n "Install $package for '$tool'? [Y/n]: "
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]] || [[ -z "$response" ]]; then
                install_package "$package" "$tool"
            fi
        else
            success "Tool '$tool' is available"
        fi
    done
}

main() {
    local tex_file=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                error "Unknown option $1"
                ;;
            *)
                if [ -z "$tex_file" ]; then
                    tex_file="$1"
                else
                    error "Multiple files specified. Please specify only one LaTeX file."
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$tex_file" ]; then
        error "No LaTeX file specified. Use -h for help."
    fi
    
    info "Starting LaTeX dependency check for $tex_file"
    if [ "$DRY_RUN" = true ]; then
        info "Running in DRY RUN mode - no packages will be installed"
    fi
    log "Started dependency check for $tex_file (DRY_RUN=$DRY_RUN)"
    
    check_prerequisites
    
    # Parse packages from LaTeX file
    local packages
    mapfile -t packages < <(parse_latex_packages "$tex_file")
    
    if [ ${#packages[@]} -eq 0 ]; then
        warning "No packages found in $tex_file"
        exit 0
    fi
    
    info "Found ${#packages[@]} packages: ${packages[*]}"
    
    local missing_packages=()
    local installed_packages=()
    
    # Check each package
    for pkg in "${packages[@]}"; do
        if check_package_installed "$pkg"; then
            success "Package '$pkg' is already available"
            installed_packages+=("$pkg")
        else
            warning "Package '$pkg' is missing"
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        success "All packages are already installed!"
    else
        info "Need to install ${#missing_packages[@]} packages"
        
        # Install missing packages
        for pkg in "${missing_packages[@]}"; do
            local fedora_pkg
            fedora_pkg=$(get_fedora_package "$pkg")
            
            if [ $? -eq 0 ]; then
                echo -n "Install $fedora_pkg for LaTeX package '$pkg'? [Y/n]: "
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]] || [[ -z "$response" ]]; then
                    install_package "$fedora_pkg" "$pkg"
                fi
            else
                warning "Could not find Fedora package for LaTeX package '$pkg'"
                log "NOTFOUND: $pkg"
            fi
        done
    fi
    
    # Check LaTeX tools
    check_latex_tools
    
    success "Dependency check completed. Log saved to $LOG_FILE"
}

# Run main function
main "$@"