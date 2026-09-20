#!/bin/bash
# Hook de demarrage de session : installe le SDK Flutter dans l'environnement
# cloud, afin que « flutter analyze » et « flutter test » y soient utilisables.
#
# Sans lui, l'environnement distant ne fournit ni flutter ni dart : aucune
# verification du code Dart n'y est possible.
#
# Le script est idempotent : une fois le SDK en place, les executions
# suivantes se contentent de reconstituer le PATH.
set -euo pipefail

# Version epinglee volontairement, pour que deux sessions ne compilent jamais
# avec deux SDK differents. Pour monter de version, mettre a jour ces deux
# valeurs ensemble (voir https://docs.flutter.dev/release/archive).
readonly FLUTTER_VERSION="3.47.5"
readonly FLUTTER_ARCHIVE_SHA256="2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb"

readonly FLUTTER_ROOT="/opt/flutter"
readonly FLUTTER_ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# Marqueur ecrit par ce script apres une installation reussie. Il sert a savoir
# quelle version est en place sans dependre de l'organisation interne du SDK :
# le fichier « version » a la racine de Flutter a existe puis disparu, s'y fier
# faisait retelecharger le SDK a chaque demarrage.
readonly INSTALL_MARKER="${FLUTTER_ROOT}/.installed-version"

# Le poste de developpement local a deja son propre SDK : ne rien y installer.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# --- Installation du SDK -----------------------------------------------------

install_flutter_sdk() {
  local archive_path
  archive_path="$(mktemp -d)/flutter.tar.xz"

  echo "Telechargement de Flutter ${FLUTTER_VERSION}..."
  curl -fSL --retry 4 --retry-delay 2 --retry-connrefused \
    -o "${archive_path}" "${FLUTTER_ARCHIVE_URL}"

  # L'archive est verifiee avant extraction : un telechargement tronque
  # produirait un SDK subtilement casse, bien plus couteux a diagnostiquer.
  echo "Verification de l'empreinte..."
  echo "${FLUTTER_ARCHIVE_SHA256}  ${archive_path}" | sha256sum --check --status

  echo "Extraction vers ${FLUTTER_ROOT}..."
  mkdir -p "$(dirname "${FLUTTER_ROOT}")"
  rm -rf "${FLUTTER_ROOT}"
  tar -xJf "${archive_path}" -C "$(dirname "${FLUTTER_ROOT}")"
  rm -rf "$(dirname "${archive_path}")"

  # Le marqueur n'est ecrit qu'une fois l'extraction terminee : une installation
  # interrompue laisse donc un SDK sans marqueur, qui sera reinstalle.
  echo "${FLUTTER_VERSION}" > "${INSTALL_MARKER}"
}

# Le SDK est-il deja present, et dans la bonne version ?
needs_install=true
if [ -x "${FLUTTER_ROOT}/bin/flutter" ]; then
  if grep -qx "${FLUTTER_VERSION}" "${INSTALL_MARKER}" 2>/dev/null; then
    needs_install=false
    echo "Flutter ${FLUTTER_VERSION} deja installe."
  else
    echo "Version de Flutter absente ou differente de ${FLUTTER_VERSION} : installation."
  fi
fi

if [ "${needs_install}" = true ]; then
  install_flutter_sdk
fi

export PATH="${FLUTTER_ROOT}/bin:${PATH}"

# Le SDK est un depot git appartenant a un autre utilisateur que celui qui
# l'execute : sans cette declaration, l'outil flutter refuse de demarrer.
git config --global --add safe.directory "${FLUTTER_ROOT}" 2>/dev/null || true

# --- Preparation de la session -----------------------------------------------

# Rend flutter et dart disponibles dans tous les shells de la session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${FLUTTER_ROOT}/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE}"
fi

# Desactive la collecte de statistiques d'usage : une session cloud ephemere
# n'a pas a en emettre, et cela supprime l'invite au premier lancement.
flutter config --no-analytics >/dev/null 2>&1 || true

# Artefacts necessaires a « flutter test » (moteur de test hote). Les telecharger
# maintenant evite une attente surprise au premier test lance dans la session.
# L'operation est quasi instantanee lorsque le cache est deja constitue.
echo "Preparation des artefacts de test..."
flutter precache --universal >/dev/null 2>&1 || \
  echo "Avertissement : precache incomplet, le premier test sera plus lent."

# Dependances du projet.
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")}"
echo "Recuperation des dependances du projet..."
flutter pub get || echo "Avertissement : echec de flutter pub get."

echo "Environnement Flutter pret : $(flutter --version | head -1)"
