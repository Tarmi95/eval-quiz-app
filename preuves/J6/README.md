# Preuves J6-A — CI sur Pull Request

| Fichier | Ce qu'il prouve |
|---|---|
| `2026-11-26_actions-premier-run-ci.png` | Premier run du workflow `CI` (PR #8, workflow placé dans `.github/workflows/`) |
| `2026-11-26_ci-verte-checks-obligatoires-approuvee.png` | Les 2 contrôles `Build & Trivy` sont **Required**, verts, PR approuvée → fusion autorisée |
| `2026-11-26_PR9-ci-rouge-fusion-bloquee.png` | PR #9 (image Debian buster obsolète) : contrôle backend en échec → **Merging is blocked** |
| `2026-11-26_ci-rouge-etape-trivy-en-echec.png` | Le job échoue bien à l'étape **Scan Trivy (bloquant sur CRITICAL)**, pas au build |

Démonstration contrôlée : la PR #9 a été fermée sans fusion et l'image n'a été publiée dans aucun registre.
Lien : https://github.com/Tarmi95/eval-quiz-app/pull/9
