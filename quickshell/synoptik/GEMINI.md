# Git Commit Authorization Rule

- When the user types the exact phrase **"Commit that shit"** (or case variants like "commit that shit"), immediately commit and push the changes to git without prompting for confirmation.
- For all other requests involving committing code, always ask the user for explicit confirmation before committing or pushing to git.
- **NEVER commit any `.json` files** (such as `settings.json`), as they contain user-specific settings.

