#!/bin/sh

set -eu

PROJECT_REF="${PROJECT_REF:-xdykcrwbkupevoanunto}"
FUNCTION_NAME="create-booking-payment-intent"

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

resolve_cli() {
  if [ -n "${SUPABASE_CLI:-}" ] && [ -x "${SUPABASE_CLI}" ]; then
    printf '%s\n' "${SUPABASE_CLI}"
    return 0
  fi

  if [ -x "${ROOT_DIR}/temp_supabase/supabase-go" ]; then
    printf '%s\n' "${ROOT_DIR}/temp_supabase/supabase-go"
    return 0
  fi

  if [ -x "${ROOT_DIR}/temp_supabase/supabase-cli" ]; then
    printf '%s\n' "${ROOT_DIR}/temp_supabase/supabase-cli"
    return 0
  fi

  if command -v supabase >/dev/null 2>&1; then
    command -v supabase
    return 0
  fi

  echo "Supabase CLI not found. Install it or set SUPABASE_CLI to the binary path." >&2
  exit 1
}

require_env() {
  var_name="$1"
  eval "var_value=\${$var_name:-}"
  if [ -z "${var_value}" ]; then
    echo "Missing required environment variable: ${var_name}" >&2
    exit 1
  fi
}

require_env SUPABASE_ACCESS_TOKEN
require_env SUPABASE_SERVICE_ROLE_KEY
require_env STRIPE_SECRET_KEY

validate_project_ref() {
  project_ref="${PROJECT_REF}"

  if [ "${#project_ref}" -ne 20 ]; then
    echo "PROJECT_REF does not look valid. Expected the 20-character Supabase project ref." >&2
    exit 1
  fi

  case "${project_ref}" in
    *[!a-z0-9]*)
      echo "PROJECT_REF does not look valid. Expected lowercase letters and numbers only." >&2
      exit 1
      ;;
  esac
}

reject_placeholder() {
  var_name="$1"
  expected_prefix="$2"
  eval "var_value=\${$var_name:-}"

  case "${var_value}" in
    your-*|changeme|example|example-*|test|test-*)
      echo "${var_name} is still set to a placeholder value. Replace it with the real secret in your terminal before deploying." >&2
      exit 1
      ;;
  esac

  if [ -n "${expected_prefix}" ]; then
    case "${var_value}" in
      ${expected_prefix}*)
        ;;
      *)
        echo "${var_name} does not look valid. Expected a value starting with ${expected_prefix}." >&2
        exit 1
        ;;
    esac
  fi
}

validate_supabase_service_role_key() {
  var_value="${SUPABASE_SERVICE_ROLE_KEY}"

  case "${var_value}" in
    your-*|changeme|example|example-*|test|test-*)
      echo "SUPABASE_SERVICE_ROLE_KEY is still set to a placeholder value. Replace it with the real secret in your terminal before deploying." >&2
      exit 1
      ;;
    sb_secret_*|eyJ*)
      return 0
      ;;
    *)
      echo "SUPABASE_SERVICE_ROLE_KEY does not look valid. Use either the new secret key that starts with sb_secret_ or the legacy service_role JWT that starts with eyJ." >&2
      exit 1
      ;;
  esac
}

reject_placeholder SUPABASE_ACCESS_TOKEN sbp_
validate_supabase_service_role_key
reject_placeholder STRIPE_SECRET_KEY sk_
validate_project_ref

SUPABASE_CLI_BIN=$(resolve_cli)

if [ ! -d "${ROOT_DIR}/supabase/functions/${FUNCTION_NAME}" ]; then
  echo "Function directory not found: supabase/functions/${FUNCTION_NAME}" >&2
  exit 1
fi

if [ ! -f "${ROOT_DIR}/supabase/functions/${FUNCTION_NAME}/index.ts" ]; then
  echo "Function entrypoint not found: supabase/functions/${FUNCTION_NAME}/index.ts" >&2
  exit 1
fi

"${SUPABASE_CLI_BIN}" secrets set \
  --project-ref "${PROJECT_REF}" \
  SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}" \
  STRIPE_SECRET_KEY="${STRIPE_SECRET_KEY}"

"${SUPABASE_CLI_BIN}" functions deploy "${FUNCTION_NAME}" --project-ref "${PROJECT_REF}"

echo "Deployed ${FUNCTION_NAME} to ${PROJECT_REF}."