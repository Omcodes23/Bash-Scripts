#!/usr/bin/env bash
#
# pve-master.sh
# Single-file menu to browse & run the latest Proxmox helper/community scripts.
# - Presents categories & scripts
# - Fetches latest script via curl and executes with "bash"
# - Preview, confirm, logging, non-interactive (-y), add custom script
#
# Usage:
#   bash pve-master.sh        # interactive
#   bash pve-master.sh -y     # non-interactive (auto-confirm)
#   bash pve-master.sh -d     # dry-run (show what would be executed)
#
# IMPORTANT:
#  Running remote scripts is powerful but can be risky. This script shows the URL,
#  lets you preview, and requires confirmation unless -y is used.
#
set -euo pipefail
IFS=$'\n\t'

# ---------------------------
# Configuration
# ---------------------------
LOGFILE="/var/log/pve-master.log"
TMPDIR="$(mktemp -d /tmp/pve-master.XXXX)"
MAP_URL="${PVE_MASTER_MAP_URL:-}"   # optional: set env PVE_MASTER_MAP_URL to load JSON map
FORCE_NO_CONFIRM=false
DRY_RUN=false
VERBOSE=true

# Default mapping. Add or edit entries here.
# Format: CATEGORY|LABEL|DESCRIPTION|URL
# Keep URLs to raw scripts (github raw, gist raw, etc.)
read -r -d '' DEFAULT_MAP <<'MAP'
System|Update & Fix Repos|Switch to no-subscription repo, update system|https://raw.githubusercontent.com/tteck/Proxmox/main/ve-helper.sh
Containers|Home Assistant LXC|Container template + tools for Home Assistant|https://raw.githubusercontent.com/tteck/Proxmox/main/ct/homeassistant.sh
Containers|Docker LXC|Create LXC with Docker + Portainer|https://raw.githubusercontent.com/tteck/Proxmox/main/ct/docker.sh
Containers|Ubuntu LXC|Create Ubuntu LXC template & optimization|https://raw.githubusercontent.com/tteck/Proxmox/main/ct/ubuntu-2204.sh
VMs|Windows Tools|Windows VM optimizations & drivers|https://raw.githubusercontent.com/tteck/Proxmox/main/vm/windows-tools.sh
ZFS|ZFS Helper|ZFS helper for tuning, pool creation, mount fixes|https://raw.githubusercontent.com/tteck/Proxmox/main/tools/zfs.sh
Passthrough|GPU/PCI Passthrough|Guides & helper for GPU passthrough|https://raw.githubusercontent.com/tteck/Proxmox/main/tools/passthrough.sh
Tools|Backup & Restore|Backup helpers & scripts|https://raw.githubusercontent.com/tteck/Proxmox/main/tools/backup.sh
Community|Network Tools|Network troubleshooting & tuning|https://raw.githubusercontent.com/tteck/Proxmox/main/tools/network.sh
MAP

# ---------------------------
# Helpers
# ---------------------------
log() {
  local ts msg
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  msg="$*"
  echo "[$ts] $msg" | tee -a "$LOGFILE"
}

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

err() {
  echo "ERROR: $*" >&2
  log "ERROR: $*"
}

confirm() {
  if $FORCE_NO_CONFIRM || [ "$DRY_RUN" = true ]; then
    return 0
  fi
  local prompt="${1:-Are you sure? (y/N): }"
  read -r -p "$prompt" ans
  case "$ans" in
    y|Y|yes|Yes) return 0 ;;
    *) return 1 ;;
  esac
}

fetch_script() {
  local url="$1" out="$2"
  if ! command -v curl >/dev/null 2>&1; then
    err "curl not found. Install curl and retry."
    return 2
  fi
  log "Fetching: $url"
  if curl -fsSL "$url" -o "$out"; then
    chmod +x "$out"
    return 0
  else
    err "Failed to fetch $url"
    return 3
  fi
}

run_script() {
  local url="$1"
  local label="$2"
  local tmpfile="$TMPDIR/$(basename "${url//\//_}").sh"
  echo
  echo ">>>> Selected: $label"
  echo "URL: $url"
  echo

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would download and execute: $url"
    log "[DRY-RUN] $url"
    return 0
  fi

  # Fetch
  if ! fetch_script "$url" "$tmpfile"; then
    err "Could not download script."
    return 4
  fi

  # Show preview option
  while true; do
    echo "Options:"
    echo "  1) Preview script"
    echo "  2) Run script NOW"
    echo "  3) Save script to ${tmpfile}"
    echo "  4) Cancel"
    read -r -p "Choose [1-4]: " c
    case "$c" in
      1)
        less "$tmpfile"
        ;;
      2)
        if confirm "Execute script now? This will run: $url (y/N): "; then
          log "Executing $url (label: $label)"
          # Execute in a subshell to avoid polluting this script's environment
          set +e
          bash "$tmpfile"
          rc=$?
          set -e
          if [ "$rc" -eq 0 ]; then
            log "Execution success: $url (rc=0)"
            echo "Done. (rc=0)"
          else
            log "Execution failed: $url (rc=$rc)"
            echo "Script exited with code $rc"
          fi
          return "$rc"
        else
          echo "Execution canceled."
          return 0
        fi
        ;;
      3)
        echo "Saved: $tmpfile"
        log "Saved script to $tmpfile"
        return 0
        ;;
      4)
        echo "Canceled."
        return 0
        ;;
      *)
        echo "Invalid option."
        ;;
    esac
  done
}

# Load mapping either from remote MAP_URL (if provided) or use DEFAULT_MAP
load_map() {
  local map_data=""
  if [ -n "$MAP_URL" ]; then
    if curl -fsSL "$MAP_URL" -o "$TMPDIR/map.txt"; then
      map_data="$(cat "$TMPDIR/map.txt")"
    else
      err "Unable to fetch map from $MAP_URL, falling back to default map."
      map_data="$DEFAULT_MAP"
    fi
  else
    map_data="$DEFAULT_MAP"
  fi
  echo "$map_data"
}

# Allow user to add custom script to mapping temporarily
add_custom_script() {
  read -r -p "Category name: " c
  read -r -p "Label (what to show in menu): " l
  read -r -p "Short description: " d
  read -r -p "Raw script URL: " u
  if [[ -z "$u" ]]; then
    echo "URL empty, canceled."
    return 1
  fi
  echo "${c}|${l}|${d}|${u}" >> "$TMPDIR/custom_map.txt"
  echo "Added to session custom scripts."
  log "Custom script added: $c|$l|$d|$u"
  return 0
}

# Build menu structure from mapping text (CATEGORY|LABEL|DESC|URL)
build_menu() {
  local map="$1"
  declare -A cats
  while IFS='|' read -r category label desc url; do
    # skip empty or comment lines
    [[ -z "$category" || "$category" =~ ^# ]] && continue
    cats["$category"]+="${label}||${desc}||${url}:::"
  done <<< "$map"

  # Print categories index
  local i=0
  local -a cat_names
  echo
  echo "==== Proxmox Helper Launcher ===="
  for k in "${!cats[@]}"; do
    cat_names[$i]="$k"
    i=$((i+1))
  done

  # Sort category names for stable order
  IFS=$'\n' sorted=($(printf '%s\n' "${cat_names[@]}" | sort -f))
  unset IFS

  # Present categories
  local idx=1
  for name in "${sorted[@]}"; do
    echo "$idx) $name"
    idx=$((idx+1))
  done
  echo "a) Add custom script"
  echo "q) Quit"
  echo

  # Read choice
  read -r -p "Choose category number (or a/q): " choice
  if [[ "$choice" =~ ^[qQ]$ ]]; then
    echo "Bye."
    exit 0
  elif [[ "$choice" =~ ^[aA]$ ]]; then
    add_custom_script
    return 1
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "Invalid choice."
    return 1
  fi
  local sel_index=$((choice-1))
  local sel_cat="${sorted[$sel_index]:-}"
  if [ -z "$sel_cat" ]; then
    echo "Invalid selection."
    return 1
  fi

  # Now show items in selected category
  echo
  echo "=== $sel_cat ==="
  IFS=':::' read -r -a entries <<< "${cats[$sel_cat]}"
  local j=1
  declare -a entry_labels entry_urls
  for e in "${entries[@]}"; do
    [[ -z "$e" ]] && continue
    IFS='||' read -r label desc url <<< "$e"
    echo "  $j) $label - $desc"
    entry_labels[$j]="$label"
    entry_urls[$j]="$url"
    j=$((j+1))
  done

  # Also show custom scripts in this category if present
  if [ -f "$TMPDIR/custom_map.txt" ]; then
    while IFS='|' read -r c l d u; do
      if [ "$c" = "$sel_cat" ]; then
        echo "  $j) ${l} - ${d} (custom)"
        entry_labels[$j]="$l"
        entry_urls[$j]="$u"
        j=$((j+1))
      fi
    done < "$TMPDIR/custom_map.txt"
  fi

  echo "  b) Back"
  echo "  q) Quit"
  read -r -p "Choose item number to run (b/q): " item_choice
  if [[ "$item_choice" =~ ^[qQ]$ ]]; then
    echo "Bye."
    exit 0
  elif [[ "$item_choice" =~ ^[bB]$ ]]; then
    return 1
  fi
  if ! [[ "$item_choice" =~ ^[0-9]+$ ]]; then
    echo "Invalid item.")
    return 1
  fi
  local label="${entry_labels[$item_choice]}"
  local url="${entry_urls[$item_choice]}"
  if [ -z "$url" ]; then
    echo "Invalid item selected."
    return 1
  fi
  run_script "$url" "$label"
  return 0
}

# ---------------------------
# Arg parsing
# ---------------------------
while getopts ":ydf" opt; do
  case $opt in
    y) FORCE_NO_CONFIRM=true ;;
    d) DRY_RUN=true ;;
    f) VERBOSE=false ;;
    *) echo "Usage: $0 [-y (auto confirm)] [-d (dry run)] [-f (no verbose)]" ; exit 1 ;;
  esac
done

# Ensure log file exists and is writable
if ! touch "$LOGFILE" >/dev/null 2>&1; then
  LOGFILE="$TMPDIR/pve-master.log"
  echo "Could not write to /var/log; using $LOGFILE"
fi

log "pve-master started (dry_run=$DRY_RUN force=$FORCE_NO_CONFIRM)"

# ---------------------------
# Main loop
# ---------------------------
main() {
  local maptext
  maptext="$(load_map)"
  # append custom_map if exists
  if [ -f "$TMPDIR/custom_map.txt" ]; then
    maptext="$maptext"$'\n'"$(cat "$TMPDIR/custom_map.txt")"
  fi

  while true; do
    if build_menu "$maptext"; then
      echo
      read -r -p "Press ENTER to continue to menu..." _
    fi
  done
}

main

