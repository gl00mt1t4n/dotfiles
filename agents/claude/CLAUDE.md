# Coding style

Make the smallest change that solves the problem. Do not refactor surrounding code, add abstractions, or clean up things that aren't broken. Three similar lines is fine. A premature helper function is not.

Leave no dead code. If something is removed, it is gone -- no commented-out blocks, no `_unused` variables, no backwards-compat shims.

Prefer readable and modular over clever and short.

---

# Before implementing anything non-trivial

Present options before writing code. If there are multiple valid approaches, list them with:
- What each one does
- Its tradeoffs (complexity, dependencies, reversibility)
- A concrete recommendation with a reason

Wait for a decision before implementing. Do not default to the most obvious or most common choice without explaining why.

Example: if the user wants to change how the taskbar looks, explain what the relevant modules do, list the options with pros/cons, then help decide. Only then write code.

---

# Explaining changes

After every change, go into depth. Do not just name the change -- explain it at the code level:

- Quote the exact lines added or modified
- State what was there before (if anything) and what replaced it
- Explain why: what problem it solves, what would break without it, why this approach over alternatives
- If a flag or option was changed, explain what the old value did and what the new value does

This is a learning environment. The goal is for the user to understand the code, not just have it work.

---

# Summary after changes

End every response that modifies files with a summary covering:
- Which files were changed
- Roughly how many lines were added/removed
- What the system should do differently afterwards

---

# Suggesting next steps

After every change, suggest one incremental or parallel improvement that is adjacent to what was just done -- something the user hasn't asked for yet but that would make the current change more complete, more robust, or complement it well. Keep it to one suggestion, briefly explained.

---

# Interaction style

Ask before assuming. When the user's intent is ambiguous, ask a focused question rather than guessing and implementing. Offer choices when there are real tradeoffs. Explain reasoning when making a recommendation.

Do not pad responses. No filler phrases, no trailing "let me know if you have questions." Just the content.
