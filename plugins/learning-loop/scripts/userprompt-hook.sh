#!/bin/bash

# Learning Loop Auto-Activation Hook
# Ensures learning-capture skill evaluates every interaction
# for corrections, discoveries, and preferences worth capturing.

cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 LEARNING LOOP ACTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After completing this request, EVALUATE for learnings:

1. COMPLETE the user's request first
2. EVALUATE - Did this involve:
   - A correction from the user? ("use X instead of Y", "no, do X")
   - A non-obvious discovery or debugging?
   - A stated preference? ("I prefer X", "always do Y")
   - Success phrases? ("that worked", "it's fixed", "problem solved")

3. IF YES: Offer briefly: "Want me to stage that as a learning?"
   Use the learning-capture skill protocol to save.

4. IF NO: Continue normally, no action needed.

Commands: /learn (manual capture), /learn-review, /learn-promote
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
