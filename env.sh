project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$project_root/env.default.sh"
if [[ -f "$project_root/env.custom.sh" ]]; then
  source "$project_root/env.custom.sh"
fi
