#!/usr/bin/env bash

#==============================================================================
# Meta-Repo Bootstrap Script
#==============================================================================
#
# SYNOPSIS
#     Bootstraps a new meta-repository from the meta-repo module template.
#
# DESCRIPTION
#     Copies the meta-repo module files to a target directory, creating a
#     ready-to-use spec-driven meta-repository with AI tool integrations.
#
#     Skips module-only files (README.md, WORKFLOW.md, scripts/) that are
#     documentation for the module itself, not part of the bootstrapped output.
#
# PARAMETERS
#     --target-path PATH          Target directory for the new meta-repo (required)
#     --tools TOOL[,TOOL...]      Comma-separated AI tools: claude-code, copilot, cursor
#                                 (default: all three)
#     --project-name NAME         Replace [Project Name] placeholders with this name
#     --dry-run                   Preview changes without making them
#     -h, --help                  Show this help message
#
# EXAMPLES
#     # Bootstrap with all tools
#     ./bootstrap.sh --target-path ~/projects/my-meta-repo
#
#     # Bootstrap with specific tools and project name
#     ./bootstrap.sh --target-path ~/projects/my-meta-repo \
#         --tools claude-code,copilot \
#         --project-name "My Project"
#
#     # Preview what would be copied
#     ./bootstrap.sh --target-path ~/projects/my-meta-repo --dry-run
#
# NOTES
#     File Name      : bootstrap.sh
#     Prerequisite   : bash 4.0 or later
#
#==============================================================================

set -euo pipefail

# Color codes for output
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_WHITE='\033[1;37m'
readonly COLOR_RESET='\033[0m'

# Resolve module root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Script variables
TARGET_PATH=""
TOOLS=(claude-code copilot cursor)
PROJECT_NAME=""
DRY_RUN=false
FILE_COUNT=0

#==============================================================================
# Helper Functions
#==============================================================================

log_info() {
    echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1" >&2
}

show_help() {
    sed -n '/^# SYNOPSIS/,/^#==/p' "$0" | sed 's/^# \?//' | sed '1d;$d'
    exit 0
}

array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# Detect sed variant for portable in-place editing
sed_in_place() {
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

should_skip_file() {
    local relative_path="$1"

    # Skip module-only files (top-level README.md, WORKFLOW.md, scripts/*)
    case "$relative_path" in
        README.md|WORKFLOW.md)
            return 0
            ;;
        scripts/*)
            return 0
            ;;
    esac

    # Skip tool dirs based on --tools selection
    if ! array_contains "claude-code" "${TOOLS[@]}"; then
        case "$relative_path" in
            .claude/*) return 0 ;;
        esac
    fi

    if ! array_contains "copilot" "${TOOLS[@]}"; then
        case "$relative_path" in
            .github/*) return 0 ;;
        esac
    fi

    if ! array_contains "cursor" "${TOOLS[@]}"; then
        case "$relative_path" in
            .cursor/*) return 0 ;;
        esac
    fi

    return 1
}

copy_file() {
    local source_path="$1"
    local dest_path="$2"

    local dest_dir
    dest_dir="$(dirname "$dest_path")"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would copy: $source_path -> $dest_path"
        FILE_COUNT=$((FILE_COUNT + 1))
        return
    fi

    mkdir -p "$dest_dir"
    cp "$source_path" "$dest_path"
    FILE_COUNT=$((FILE_COUNT + 1))
}

#==============================================================================
# Parse Arguments
#==============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-path)
            TARGET_PATH="$2"
            shift 2
            ;;
        --tools)
            IFS=',' read -ra TOOLS <<< "$2"
            shift 2
            ;;
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

#==============================================================================
# Validate Arguments
#==============================================================================

if [[ -z "$TARGET_PATH" ]]; then
    log_error "Target path is required. Use --target-path to specify."
    echo "Use --help for usage information"
    exit 1
fi

# Validate tool names
for tool in "${TOOLS[@]}"; do
    if [[ ! "$tool" =~ ^(claude-code|copilot|cursor)$ ]]; then
        log_error "Invalid tool: $tool. Valid values: claude-code, copilot, cursor"
        exit 1
    fi
done

#==============================================================================
# Main Script Logic
#==============================================================================

echo ""
echo -e "${COLOR_CYAN}========================================${COLOR_RESET}"
echo -e "${COLOR_CYAN}Meta-Repo Bootstrap${COLOR_RESET}"
echo -e "${COLOR_CYAN}========================================${COLOR_RESET}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
    echo ""
fi

log_info "Source module: $MODULE_ROOT"
log_info "Target path: $TARGET_PATH"
log_info "Tools: ${TOOLS[*]}"
if [[ -n "$PROJECT_NAME" ]]; then
    log_info "Project name: $PROJECT_NAME"
fi
echo ""

#==============================================================================
# Create Target Directory
#==============================================================================

if [[ "$DRY_RUN" != true ]]; then
    mkdir -p "$TARGET_PATH"
fi

#==============================================================================
# Copy Files
#==============================================================================

echo -e "${COLOR_YELLOW}--- Copying Files ---${COLOR_RESET}"

while IFS= read -r -d '' file; do
    relative_path="${file#$MODULE_ROOT/}"

    if should_skip_file "$relative_path"; then
        continue
    fi

    dest_file="$TARGET_PATH/$relative_path"
    copy_file "$file" "$dest_file"
done < <(find "$MODULE_ROOT" -type f -print0)

echo ""

#==============================================================================
# Create Empty Spec Directories with .gitkeep
#==============================================================================

echo -e "${COLOR_YELLOW}--- Creating Spec Directories ---${COLOR_RESET}"

spec_types=(bug chore design feature planning)

for spec_type in "${spec_types[@]}"; do
    spec_dir="$TARGET_PATH/specs/$spec_type"
    gitkeep="$spec_dir/.gitkeep"

    if [[ "$DRY_RUN" == true ]]; then
        if [[ ! -f "$gitkeep" ]]; then
            log_info "Would create: specs/$spec_type/.gitkeep"
        fi
    else
        mkdir -p "$spec_dir"
        if [[ ! -f "$gitkeep" ]]; then
            touch "$gitkeep"
            log_info "Created: specs/$spec_type/.gitkeep"
        fi
    fi
done

echo ""

#==============================================================================
# Replace Placeholders
#==============================================================================

if [[ -n "$PROJECT_NAME" ]]; then
    echo -e "${COLOR_YELLOW}--- Replacing Placeholders ---${COLOR_RESET}"

    # Files to check for [Project Name] placeholder
    placeholder_files=(
        "$TARGET_PATH/AGENTS.md"
        "$TARGET_PATH/CLAUDE.md"
        "$TARGET_PATH/project/README.md"
    )

    # Also include any .yaml files in project/
    if [[ -d "$TARGET_PATH/project" ]]; then
        while IFS= read -r -d '' yaml_file; do
            placeholder_files+=("$yaml_file")
        done < <(find "$TARGET_PATH/project" -name "*.yaml" -type f -print0)
    fi

    # Also include template files that may have [Project Name]
    if [[ -d "$TARGET_PATH/docs/templates" ]]; then
        while IFS= read -r -d '' tmpl_file; do
            placeholder_files+=("$tmpl_file")
        done < <(find "$TARGET_PATH/docs/templates" -type f -print0)
    fi

    for target_file in "${placeholder_files[@]}"; do
        if [[ -f "$target_file" ]]; then
            if grep -q '\[Project Name\]' "$target_file" 2>/dev/null; then
                if [[ "$DRY_RUN" == true ]]; then
                    log_info "Would replace [Project Name] in: ${target_file#$TARGET_PATH/}"
                else
                    sed_in_place "s/\[Project Name\]/$PROJECT_NAME/g" "$target_file"
                    log_success "Replaced [Project Name] in: ${target_file#$TARGET_PATH/}"
                fi
            fi
        fi
    done

    echo ""
fi

#==============================================================================
# Initialize Git Repository
#==============================================================================

if [[ "$DRY_RUN" != true ]]; then
    if [[ ! -d "$TARGET_PATH/.git" ]]; then
        echo -e "${COLOR_YELLOW}--- Initializing Git Repository ---${COLOR_RESET}"
        (cd "$TARGET_PATH" && git init)
        echo ""
    fi
fi

#==============================================================================
# Summary
#==============================================================================

echo -e "${COLOR_CYAN}========================================${COLOR_RESET}"
echo -e "${COLOR_CYAN}Bootstrap Summary${COLOR_RESET}"
echo -e "${COLOR_CYAN}========================================${COLOR_RESET}"
echo ""

echo -e "${COLOR_WHITE}Target path:${COLOR_RESET} $TARGET_PATH"
echo -e "${COLOR_WHITE}Tools installed:${COLOR_RESET} ${TOOLS[*]}"
echo -e "${COLOR_WHITE}Files copied:${COLOR_RESET} $FILE_COUNT"
if [[ -n "$PROJECT_NAME" ]]; then
    echo -e "${COLOR_WHITE}Project name:${COLOR_RESET} $PROJECT_NAME"
fi
echo ""

if [[ "$DRY_RUN" == true ]]; then
    log_warning "This was a dry run. No files were actually copied."
else
    echo -e "${COLOR_YELLOW}Next Steps:${COLOR_RESET}"
    echo -e "${COLOR_WHITE}1. Edit AGENTS.md — fill in the 'Your Project' and 'Communication Style' sections${COLOR_RESET}"
    echo -e "${COLOR_WHITE}2. Edit project/project-repositories.yaml — add your repositories${COLOR_RESET}"
    echo -e "${COLOR_WHITE}3. Start creating specs with /new-spec (Claude Code) or equivalent${COLOR_RESET}"
    echo ""
    log_success "Bootstrap complete!"
fi
