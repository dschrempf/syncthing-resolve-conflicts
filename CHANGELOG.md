# Changelog

## [1.3.0] - 2026-05-13

- Add `-F`/`--fd` option to use `fd` for finding conflicts.
- Add `-c`/`--config` option to scan all syncthing-configured folders;
  combinable with `-f` or `-F`.
- Fix several robustness issues: explicit directory passing to `cmd()`,
  `realpath` normalization of config folders, narrowed XML parsing in
  `get_syncthing_folders`, color init ordering.
- Add bats test suite covering CLI flags, config parsing, and conflict
  processing.

## [1.2.0] - 2025-04-10

- Maintenance: code formatting, improved README, error checks for `locate`.
- Fix `-d` with paths containing spaces.

## [1.1.0] - 2020-02-23

- Add `-f`/`--find` and `-d`/`--directory` options.
- Handle recursive conflicts (depth ≥ 2) separately.

## [1.0.x]

- Initial release.
