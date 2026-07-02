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
#     Can run interactively (no args) or non-interactively with flags.
#     Writes a template-manifest.yaml for version-controlled syncing.
#
# PARAMETERS
#     --target-path PATH          Target directory for the new meta-repo
#     --project-name NAME         Replace [Project Name] placeholders with this name
#     --dry-run                   Preview changes without making them
#     -h, --help                  Show this help message
#
# EXAMPLES
#     # Interactive mode
#     ./bootstrap.sh
#
#     # Non-interactive with flags
#     ./bootstrap.sh --target-path ~/projects/my-meta-repo --project-name "my-platform"
#
#     # Preview what would be copied
#     ./bootstrap.sh --target-path ~/projects/my-meta-repo --dry-run
#
#==============================================================================

set -euo pipefail

readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_WHITE='\033[1;37m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET_PATH=""
PROJECT_NAME=""
DRY_RUN=false
INTERACTIVE=false
FILE_COUNT=0

#==============================================================================
# Helper Functions
#==============================================================================

log_info()    { echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} $1"; }
log_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"; }
log_warning() { echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"; }
log_error()   { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1" >&2; }

show_help() {
    sed -n '/^# SYNOPSIS/,/^#==/p' "$0" | sed 's/^# \?//' | sed '1d;$d'
    exit 0
}

sed_in_place() {
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

should_skip_file() {
    local relative_path="$1"
    case "$relative_path" in
        .git/*|repos/*|_deprecated/*|_local/*|tmp/*|_working/*|.discovery/*|.DS_Store)
            return 0 ;;
        specs/*/repo/*|specs/*/context/scratch/*|org/sources/*)
            return 0 ;;
    esac
    return 1
}

copy_file() {
    local source_path="$1" dest_path="$2"
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would copy: ${source_path#$MODULE_ROOT/}"
    else
        mkdir -p "$(dirname "$dest_path")"
        cp "$source_path" "$dest_path"
    fi
    FILE_COUNT=$((FILE_COUNT + 1))
}

get_template_version() {
    if [[ -f "$MODULE_ROOT/template-manifest.yaml" ]]; then
        grep 'template_version:' "$MODULE_ROOT/template-manifest.yaml" | head -1 | sed 's/.*"\(.*\)".*/\1/'
    else
        echo "1.0.0"
    fi
}

#==============================================================================
# Parse Arguments
#==============================================================================

if [[ $# -eq 0 ]]; then
    INTERACTIVE=true
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-path)   TARGET_PATH="$2"; shift 2 ;;
        --project-name)  PROJECT_NAME="$2"; shift 2 ;;
        --dry-run)       DRY_RUN=true; shift ;;
        -h|--help)       show_help ;;
        *)               log_error "Unknown option: $1"; echo "Use --help for usage information"; exit 1 ;;
    esac
done

#==============================================================================
# Interactive Mode
#==============================================================================

if [[ "$INTERACTIVE" == true ]]; then
    echo ""
    echo -e "${COLOR_BOLD}╭─────────────────────────────────────────────╮${COLOR_RESET}"
    echo -e "${COLOR_BOLD}│  AE Harness Platform — New Instance Setup   │${COLOR_RESET}"
    echo -e "${COLOR_BOLD}╰─────────────────────────────────────────────╯${COLOR_RESET}"
    echo ""

    read -rp "$(echo -e "${COLOR_CYAN}?${COLOR_RESET}") Project name (e.g. acme-platform): " PROJECT_NAME
    if [[ -z "$PROJECT_NAME" ]]; then
        log_error "Project name is required."; exit 1
    fi

    # Normalize: lowercase, replace spaces/underscores with hyphens, append -meta-repo
    DIR_NAME="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')"
    [[ "$DIR_NAME" != *-meta-repo ]] && DIR_NAME="${DIR_NAME}-meta-repo"

    DEFAULT_TARGET="../$DIR_NAME"
    read -rp "$(echo -e "${COLOR_CYAN}?${COLOR_RESET}") Target directory [$DEFAULT_TARGET]: " TARGET_PATH
    TARGET_PATH="${TARGET_PATH:-"$DEFAULT_TARGET"}"

    echo ""
fi

#==============================================================================
# Validate
#==============================================================================

if [[ -z "$TARGET_PATH" ]]; then
    log_error "Target path is required. Use --target-path or run without args for interactive mode."
    exit 1
fi

if [[ "$TARGET_PATH" != /* ]]; then
    TARGET_PATH="$(pwd)/$TARGET_PATH"
fi

if [[ -d "$TARGET_PATH" ]] && [[ "$DRY_RUN" != true ]]; then
    log_error "Directory already exists: $TARGET_PATH"; exit 1
fi

#==============================================================================
# Main
#==============================================================================

TEMPLATE_VERSION="$(get_template_version)"

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
log_info "Template version: $TEMPLATE_VERSION"
if [[ -n "$PROJECT_NAME" ]]; then
    log_info "Project name: $PROJECT_NAME"
fi
echo ""

#==============================================================================
# Copy Files
#==============================================================================

if [[ "$DRY_RUN" != true ]]; then
    mkdir -p "$TARGET_PATH"
fi

echo -e "${COLOR_YELLOW}--- Copying Files ---${COLOR_RESET}"

while IFS= read -r -d '' file; do
    relative_path="${file#$MODULE_ROOT/}"
    if should_skip_file "$relative_path"; then continue; fi
    copy_file "$file" "$TARGET_PATH/$relative_path"
done < <(find "$MODULE_ROOT" -type f -not -path '*/.git/*' -print0)

echo ""

#==============================================================================
# Create Spec Directories
#==============================================================================

echo -e "${COLOR_YELLOW}--- Creating Spec Directories ---${COLOR_RESET}"

for spec_type in bug chore design feature planning; do
    spec_dir="$TARGET_PATH/specs/$spec_type"
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would create: specs/$spec_type/.gitkeep"
    else
        mkdir -p "$spec_dir"
        [[ -f "$spec_dir/.gitkeep" ]] || touch "$spec_dir/.gitkeep"
        log_info "Created: specs/$spec_type/.gitkeep"
    fi
done

if [[ "$DRY_RUN" != true ]]; then
    mkdir -p "$TARGET_PATH/repos"
    touch "$TARGET_PATH/repos/.gitkeep"
fi

echo ""

#==============================================================================
# Write Template Manifest (Derived)
#==============================================================================

if [[ "$DRY_RUN" != true ]]; then
    echo -e "${COLOR_YELLOW}--- Writing Template Manifest ---${COLOR_RESET}"

    cat > "$TARGET_PATH/template-manifest.yaml" << EOF
# template-manifest.yaml — derived instance
# DO NOT DELETE — used by sync-from-template.sh to pull updates

template_version: "$TEMPLATE_VERSION"
manifest_version: "1"

# Upstream template repo — used by sync-from-template.sh
upstream:
  repo: ""  # set to your local clone path or git URL of ae-harness-platform-poc
  pinned_at: "$TEMPLATE_VERSION"
  created_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  project_name: "$PROJECT_NAME"

# Framework paths — synced wholesale (overwritten) from template
framework:
  - .claude/
  - scripts/
  - playbooks/
  - docs/
  - architecture/README.md
  - architecture/data-modeling-conventions.md
  - META-REPO-GUIDE.md
  - CLAUDE.md
  - .gitignore
  - .env.acli.example

# Merge paths — merged (not overwritten) during sync
merge:
  - AGENTS.md

# Project paths — owned by this repo, never overwritten
project:
  - project/
  - specs/
  - repos/
  - org/
  - planning/
  - README.md
  - template-manifest.yaml
EOF

    log_success "template-manifest.yaml written (pinned to v$TEMPLATE_VERSION)"
    echo ""
fi

#==============================================================================
# Write Sync Script
#==============================================================================

if [[ "$DRY_RUN" != true ]]; then
    echo -e "${COLOR_YELLOW}--- Installing sync-from-template.sh ---${COLOR_RESET}"

    cat > "$TARGET_PATH/scripts/sync-from-template.sh" << 'SYNCEOF'
#!/usr/bin/env bash
set -euo pipefail

# sync-from-template.sh
# Pulls latest template updates into this derived harness repo.
# Reads framework paths from the source template-manifest.yaml and syncs them.
# Merge paths are flagged for manual review.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/template-manifest.yaml"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYAN}▸${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
err()   { echo -e "${RED}✗${NC} $1" >&2; }

if [[ ! -f "$MANIFEST" ]]; then
    err "No template-manifest.yaml found. Is this a harness-derived repo?"
    exit 1
fi

# Read upstream repo path
SOURCE_PATH=$(grep '  repo:' "$MANIFEST" | head -1 | sed 's/.*: *"\(.*\)"/\1/' | sed "s/'//g")
if [[ -z "$SOURCE_PATH" || ! -d "$SOURCE_PATH" ]]; then
    err "Template upstream not found at: $SOURCE_PATH"
    echo "  Set 'upstream.repo' in template-manifest.yaml to your local clone of ae-harness-platform-poc."
    exit 1
fi

SOURCE_MANIFEST="$SOURCE_PATH/template-manifest.yaml"
if [[ ! -f "$SOURCE_MANIFEST" ]]; then
    err "Template source missing template-manifest.yaml"; exit 1
fi

LOCAL_VERSION=$(grep 'pinned_at:' "$MANIFEST" | sed 's/.*"\(.*\)".*/\1/')
REMOTE_VERSION=$(grep 'template_version:' "$SOURCE_MANIFEST" | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo ""
echo -e "${BOLD}AE Harness Template Sync${NC}"
echo -e "  Local pinned version:  ${LOCAL_VERSION:-unknown}"
echo -e "  Template version:      ${REMOTE_VERSION:-unknown}"
echo ""

if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then
    ok "Already up to date (v$LOCAL_VERSION)"; exit 0
fi

# Parse framework paths from source manifest
parse_list() {
    local section="$1" file="$2"
    local in_section=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^${section}: ]]; then in_section=true; continue; fi
        if $in_section; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
                echo "${BASH_REMATCH[1]}"
            elif [[ ! "$line" =~ ^[[:space:]] ]]; then
                break
            fi
        fi
    done < "$file"
}

# Sync framework paths (overwrite)
mapfile -t FRAMEWORK_PATHS < <(parse_list "framework" "$SOURCE_MANIFEST")

if [[ ${#FRAMEWORK_PATHS[@]} -eq 0 ]]; then
    err "No framework paths found in template manifest"; exit 1
fi

info "Syncing ${#FRAMEWORK_PATHS[@]} framework paths..."
echo ""

for path in "${FRAMEWORK_PATHS[@]}"; do
    src="$SOURCE_PATH/$path"
    dst="$REPO_ROOT/$path"
    if [[ ! -e "$src" ]]; then echo "  skip (not found): $path"; continue; fi
    if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        rsync -a --delete "$src/" "$dst/"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    fi
    echo "  synced: $path"
done

# Flag merge paths for manual review
mapfile -t MERGE_PATHS < <(parse_list "merge" "$SOURCE_MANIFEST")

if [[ ${#MERGE_PATHS[@]} -gt 0 ]]; then
    echo ""
    info "Merge paths (review manually):"
    for path in "${MERGE_PATHS[@]}"; do
        src="$SOURCE_PATH/$path"
        dst="$REPO_ROOT/$path"
        if [[ -f "$src" && -f "$dst" ]]; then
            if ! diff -q "$src" "$dst" > /dev/null 2>&1; then
                echo "  changed: $path"
                echo "    diff: diff \"$dst\" \"$src\""
            fi
        fi
    done
fi

# Update pinned version
if [[ -n "$REMOTE_VERSION" ]]; then
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "s/pinned_at: .*/pinned_at: \"$REMOTE_VERSION\"/" "$MANIFEST"
    else
        sed -i '' "s/pinned_at: .*/pinned_at: \"$REMOTE_VERSION\"/" "$MANIFEST"
    fi
fi

echo ""
ok "Sync complete — now at template version $REMOTE_VERSION"
echo ""
echo "Review changes with: git diff"
echo "Commit when ready:   git add -A && git commit -m 'chore: sync harness template to v$REMOTE_VERSION'"
SYNCEOF

    chmod +x "$TARGET_PATH/scripts/sync-from-template.sh"
    log_success "sync-from-template.sh installed"
    echo ""
fi

#==============================================================================
# Replace Placeholders
#==============================================================================

if [[ -n "$PROJECT_NAME" ]]; then
    echo -e "${COLOR_YELLOW}--- Replacing Placeholders ---${COLOR_RESET}"

    placeholder_files=("$TARGET_PATH/AGENTS.md" "$TARGET_PATH/CLAUDE.md" "$TARGET_PATH/project/README.md")

    if [[ -d "$TARGET_PATH/project" ]]; then
        while IFS= read -r -d '' yaml_file; do
            placeholder_files+=("$yaml_file")
        done < <(find "$TARGET_PATH/project" -name "*.yaml" -type f -print0)
    fi

    for target_file in "${placeholder_files[@]}"; do
        if [[ -f "$target_file" ]] && grep -q '\[Project Name\]' "$target_file" 2>/dev/null; then
            if [[ "$DRY_RUN" == true ]]; then
                log_info "Would replace [Project Name] in: ${target_file#$TARGET_PATH/}"
            else
                sed_in_place "s/\[Project Name\]/$PROJECT_NAME/g" "$target_file"
                log_success "Replaced [Project Name] in: ${target_file#$TARGET_PATH/}"
            fi
        fi
    done
    echo ""
fi

#==============================================================================
# Customize README
#==============================================================================

if [[ "$DRY_RUN" != true ]]; then
    cat > "$TARGET_PATH/README.md" << EOF
# ${PROJECT_NAME:-"Meta-Repo"}

> Spec-driven meta-repository powered by the AE Harness Platform.

## Quick Start

1. Install [Claude Code](https://claude.ai/code) CLI
2. Run \`claude\` in the repo root to begin

## Syncing Template Updates

Pull the latest harness template updates:

\`\`\`bash
./scripts/sync-from-template.sh
\`\`\`

## Structure

| Directory      | Purpose                                    |
|----------------|--------------------------------------------|
| \`specs/\`       | Feature specifications                     |
| \`project/\`     | Project config, repo registry, plans       |
| \`architecture/\`| Architecture decisions and conventions     |
| \`playbooks/\`   | Reusable workflow playbooks                |
| \`scripts/\`     | Automation scripts                         |
| \`.claude/\`     | Claude Code agents and commands            |
EOF
fi

#==============================================================================
# Initialize Git Repository
#==============================================================================

if [[ "$DRY_RUN" != true ]] && [[ ! -d "$TARGET_PATH/.git" ]]; then
    echo -e "${COLOR_YELLOW}--- Initializing Git Repository ---${COLOR_RESET}"
    (cd "$TARGET_PATH" && git init -q && git add -A && git commit -q -m "feat: initialize harness from ae-harness-platform template v$TEMPLATE_VERSION")
    log_success "Git repository initialized with initial commit"
    echo ""
fi

#==============================================================================
# Summary & Next Steps
#==============================================================================

echo -e "${COLOR_CYAN}========================================${COLOR_RESET}"
echo -e "${COLOR_CYAN}Bootstrap Complete${COLOR_RESET}"
echo -e "${COLOR_CYAN}========================================${COLOR_RESET}"
echo ""

echo -e "${COLOR_WHITE}Target path:${COLOR_RESET}      $TARGET_PATH"
echo -e "${COLOR_WHITE}Files copied:${COLOR_RESET}      $FILE_COUNT"
echo -e "${COLOR_WHITE}Template version:${COLOR_RESET}  $TEMPLATE_VERSION"
if [[ -n "$PROJECT_NAME" ]]; then
    echo -e "${COLOR_WHITE}Project name:${COLOR_RESET}     $PROJECT_NAME"
fi
echo ""

if [[ "$DRY_RUN" == true ]]; then
    log_warning "This was a dry run. No files were actually copied."
else
    echo -e "${COLOR_BOLD}Next Steps:${COLOR_RESET}"
    echo ""
    echo "  1. Create a GitHub repository for your team"
    echo "     gh repo create your-org/${PROJECT_NAME:-meta-repo} --private"
    echo ""
    echo "  2. Wire up the remote and push"
    echo "     cd $TARGET_PATH"
    echo "     git remote add origin git@github.com:your-org/${PROJECT_NAME:-meta-repo}.git"
    echo "     git push -u origin main"
    echo ""
    echo "  3. Configure the template upstream (for future syncs)"
    echo "     cd $TARGET_PATH"
    echo "     git remote add template-upstream https://github.com/Slalom/ae-harness-platform-poc.git"
    echo ""
    echo "  4. Configure your project"
    echo "     - Edit project/project-repositories.yaml to register your app repos"
    echo "     - Update project/product-brief.md with your project context"
    echo ""
    echo "  5. Start using Claude Code"
    echo "     cd $TARGET_PATH"
    echo "     claude"
    echo ""
    echo -e "${COLOR_CYAN}Sync template updates later:${COLOR_RESET}  ./scripts/sync-from-template.sh"
    echo ""
    log_success "Done!"
fi
