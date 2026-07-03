#!/usr/bin/env bash
# Installe les skills Rawbank globalement pour Cursor AI.
# Portable : $HOME uniquement, aucun chemin absolu machine.
#
# Usage (depuis la racine du repo GitHub rawbank-cursor-skills) :
#   chmod +x install-rawbank-skills.sh
#   ./install-rawbank-skills.sh
#
# Variables :
#   INSTALL_AGENTS_SKILLS=0  → n'installe que dans ~/.cursor/skills/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="${SCRIPT_DIR}"

CURSOR_SKILLS="${HOME}/.cursor/skills"
AGENTS_SKILLS="${HOME}/.agents/skills"

REQUIRED_SKILLS=(rawbank-backend rawbank-frontend)

install_skill() {
  local name="$1"
  local target_base="$2"
  local source="${SKILLS_SRC}/${name}"
  local target="${target_base}/${name}"

  if [[ ! -f "${source}/SKILL.md" ]]; then
    echo "✗ Manquant : ${source}/SKILL.md" >&2
    echo "  Exécutez ce script depuis la racine du repo rawbank-cursor-skills." >&2
    exit 1
  fi

  echo "→ ${name} → ${target}"
  mkdir -p "${target_base}"
  rm -rf "${target}"
  cp -R "${source}" "${target}"
}

remove_legacy() {
  local target_base="$1"
  rm -rf "${target_base}/gopass-backend" "${target_base}/gopass-frontend"
}

echo "Installation des skills Rawbank..."
echo "Source : ${SKILLS_SRC}"
echo ""

for skill in "${REQUIRED_SKILLS[@]}"; do
  if [[ ! -d "${SKILLS_SRC}/${skill}" ]]; then
    echo "✗ Dossier skill introuvable : ${SKILLS_SRC}/${skill}" >&2
    exit 1
  fi
done

remove_legacy "${CURSOR_SKILLS}"
remove_legacy "${AGENTS_SKILLS}"

install_skill "rawbank-backend" "${CURSOR_SKILLS}"
install_skill "rawbank-frontend" "${CURSOR_SKILLS}"

if [[ "${INSTALL_AGENTS_SKILLS:-1}" == "1" ]]; then
  install_skill "rawbank-backend" "${AGENTS_SKILLS}"
  install_skill "rawbank-frontend" "${AGENTS_SKILLS}"
fi

echo ""
echo "✓ Skills installés :"
echo "  - ${CURSOR_SKILLS}/rawbank-backend"
echo "  - ${CURSOR_SKILLS}/rawbank-frontend"
if [[ "${INSTALL_AGENTS_SKILLS:-1}" == "1" ]]; then
  echo "  - ${AGENTS_SKILLS}/rawbank-backend"
  echo "  - ${AGENTS_SKILLS}/rawbank-frontend"
fi
echo ""
echo "Documentation : references/paths-convention.md dans chaque skill (index autonome)."
echo "Redémarrez Cursor ou ouvrez un nouveau chat pour que les skills soient découverts."
