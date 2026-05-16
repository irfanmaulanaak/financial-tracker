# Style and conventions

Follow AGENTS.md: KISS, internal 2-5 user app, small scoped changes, no over-engineering, no silent fallbacks. Expected issues should use explicit result/state where practical; unexpected issues should fail loud via throw/error/toast.

Use existing Flutter/Riverpod/go_router patterns. Keep files under roughly 400 LOC when practical. Prefer standard library and existing helpers before new dependencies. Add regression tests when fixing bugs if it fits.

Design direction: warm cream editorial theme from claude-design, Newsreader display + Inter/Geist-like sans body, FtColors palette, reusable Eyebrow. claude-design is a visual/UX reference, not portable code.