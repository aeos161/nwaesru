# Page 57 BLAKE controls: superseded combined proposal

The user selected **BLAKE2b-512 first** on 2026-10-05. The actionable plan is
[page-57-blake2b-control.md](page-57-blake2b-control.md), using existing Ruby
OpenSSL support with no new crypto gem, native extension or build work.

The combined proposal is retained in Git history at `8724e8b`. Its original
BLAKE-512 dependency, native binding and packaging suggestions are deferred,
not approved implementation instructions. Original BLAKE needs a fresh plan
and dependency review after this milestone; it does not block BLAKE2b.
