# shellcheck shell=bash
# Add the project-wide timeout to commands supplied by external fragments.
# Keep the variable expansion literal: it belongs in the generated lefthook config.
sed -i -E "s#(run: )lefthook-#\1timeout --foreground \${LEFTHOOK_GUARDRAIL_TIMEOUT:-30} lefthook-#" lefthook.yml

# The pinned base fragment currently defines these checks only for pre-commit.
# Keep the generated configuration symmetric with the repository contract.
if ! awk '/^pre-push:/{p=1} p && /^    gitleaks:/{found=1} END{exit !found}' lefthook.yml; then
  awk '
    /^pre-push:/{in_push=1; print; next}
    in_push && /^[^ ]/{in_push=0}
    in_push && /^  commands:$/ {
      print
      print "    gitleaks:\n      run: timeout --foreground ${LEFTHOOK_GUARDRAIL_TIMEOUT:-30} lefthook-gitleaks {push_files}"
      print "    git-conflict-markers:\n      run: timeout --foreground ${LEFTHOOK_GUARDRAIL_TIMEOUT:-30} lefthook-git-conflict-markers {push_files}"
      print "    git-no-local-paths:\n      run: timeout --foreground ${LEFTHOOK_GUARDRAIL_TIMEOUT:-30} lefthook-git-no-local-paths {push_files}"
      next
    }
    {print}
  ' lefthook.yml >lefthook.yml.tmp
  mv lefthook.yml.tmp lefthook.yml
fi
