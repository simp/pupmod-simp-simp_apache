# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-simp_apache` is a SIMP Puppet module that installs and configures an
**Apache (`httpd`) web server** hardened to SIMP conventions. It manages the
`httpd` package(s), lays down `httpd.conf` and the SSL configuration from
templates, creates the `apache` user/group, manages the SELinux booleans Apache
needs, optionally rsyncs the web root from a SIMP rsync server, and wires Apache
into the surrounding SIMP feature modules (iptables, rsyslog, PKI, haveged).

This is an **older, legacy module**: its own `metadata.json` summary flags it as
"legacy, conflicts with puppetlabs-apache," and the docstring on
`manifests/init.pp:6-7` states the long-term intent is to migrate to the
Puppet Labs `apache` module. It carries hand-rolled ERB templates, a custom
`htaccess` type/provider, and helper functions rather than delegating to a
maintained upstream Apache module. Treat it as a maintenance target: prefer
minimal, surgical changes over rewrites.

The module is structured as an orchestrating entry class (`simp_apache`) that
`include`s a small set of component classes (`install`, `conf`, `service`, and
optionally `ssl`), plus a `site` define for dropping in per-site vhost configs.

### Business logic

- **`simp_apache` (`manifests/init.pp:31`)** — Public entry class; consumers
  `include 'simp_apache'`. It calls `simplib::assert_metadata($module_name)`
  and then `include`s `simp_apache::install`, `simp_apache::conf`, and
  `simp_apache::service`. When `$ssl` is true (default) it also `include`s
  `simp_apache::ssl`. Key parameters (`init.pp:31-38`):
  - `$data_dir` (`Stdlib::AbsolutePath`, default `/var/www`) — where web data
    lives. (The docstring says `/srv/www` "for legacy reasons," but the code
    default is `/var/www`; trust the code.)
  - `$ssl` (`Boolean`, default `true`) — master switch for the SSL class.
  - `$rsync_source` (`String`) — defaults to
    `"apache_${environment}_${os.name}/www"`.
  - `$rsync_server` (`Simplib::Host`) — `simp_options::rsync::server`, default
    `127.0.0.1`.
  - `$rsync_timeout` (`Integer`) — `simp_options::rsync::timeout`, default `2`.
  - `$rsync_web_root` (`Boolean`, default `true`) — whether to rsync the web
    root.

  Resources and control flow:
  - **Ordering** (`init.pp:51-54`): `install` runs before `simp_apache`, `conf`,
    and (when enabled) `ssl`; `install` and `conf` both `notify` `service`.
  - `group { 'apache' }` and `user { 'apache' }` are pinned to **uid/gid 48**
    with `allowdupe => false`, `shell => /sbin/nologin`, home
    `/usr/share/httpd`, and `membership => minimum` (`init.pp:58-62,93-102`).
  - **rsync branch** (`init.pp:64-79`): when `$rsync_web_root`, `include 'rsync'`
    and declare `rsync { 'site' }` pulling `$rsync_source` to `/var`, with the
    per-host rsync **password sourced from `simplib::passgen(...)`**
    (`init.pp:72`) and `delete => false`.
  - **SELinux branch** (`init.pp:81-91`): only when the SELinux mode fact is set
    and not `disabled`, sets four `selboolean`s persistently on:
    `httpd_verify_dns`, `allow_ypbind`, `allow_httpd_mod_auth_pam`,
    `httpd_can_network_connect`.

- **`simp_apache::install` (`manifests/install.pp:12`)** — Private class
  (`assert_private()` at `install.pp:17`). Manages `package { 'httpd' }`, and
  `package { 'mod_ssl' }` **only when `$simp_apache::ssl`** is true
  (`install.pp:23-27`). All three ensure params
  (`$httpd_ensure`, `$mod_ldap_ensure`, `$mod_ssl_ensure`) default to
  `simp_options::package_ensure` → `'installed'`.

- **`simp_apache::conf` (`manifests/conf.pp:62`)** — Renders
  `/etc/httpd/conf/httpd.conf` from an ERB template
  (`conf.pp:116-122`), manages the `conf`/`conf.d` directories (with
  `purge => $purge`, default `true` — **this purges unmanaged files**), the
  `magic` file (EPP, `replace => false`), a symlink farm
  (`/etc/httpd/logs`, `/etc/httpd/modules`, `/etc/httpd/run`), and the
  `$data_dir`. The modules symlink target is arch-dependent:
  `/usr/lib64/httpd/modules` on `x86_64`, else `/usr/lib/httpd/modules`
  (`conf.pp:124-127`). Networks in `$allowroot` are normalized through
  `simp_apache::munge_httpd_networks()` (`conf.pp:100`). This class carries the
  bulk of the tunables (prefork/worker MPM sizing, keepalive, logging, etc.).
  - **firewall branch** (`conf.pp:186-194`): when `$firewall`, `include
    'iptables'` and open the `$listen` ports (default `[80]`) via
    `iptables::listen::tcp_stateful` with `trusted_nets => $l_allowroot`.
  - **syslog branch** (`conf.pp:196-208`): when `$syslog`, `include '::rsyslog'`
    and add two `rsyslog::rule::local` rules routing `httpd` error and access
    logs under `$syslog_target` (default `/var/log/httpd`).

- **`simp_apache::service` (`manifests/service.pp:31`)** — Manages
  `service { 'httpd' }` (`ensure => running`, `enable => true`) only when
  `$manage` (default `true`). If `$hasrestart` is false (the default), a custom
  `$restart` command is used that tries `systemctl reload` then falls back to
  `restart` (`service.pp:38-53`). When `$manage` is false you may need to add
  the service to `svckill::ignore` (per the docstring).

- **`simp_apache::ssl` (`manifests/ssl.pp:89`)** — Renders
  `/etc/httpd/conf.d/ssl.conf` from ERB (`ssl.pp:112-119`), notifying the
  service. Optionally `include 'haveged'` (`ssl.pp:110`) and `include 'iptables'`
  to open the SSL `$listen` ports (default `[443]`). When `$pki` is truthy,
  `pki::copy { 'simp_apache' }` manages certs under
  `/etc/pki/simp_apps/simp_apache/x509` (`ssl.pp:99,131-138`). Defaults:
  `$ssl_protocols = ['TLSv1.2']`, `$sslverifyclient = 'require'`,
  `$sslverifydepth = 10`, `$ssl_honor_cipher_order = true`.

- **`simp_apache::site` (`manifests/site.pp:14`)** — Define. Drops a
  `/etc/httpd/conf.d/${name}.conf` file, `notify`ing the service. With the
  default `$content = 'base'` it renders a `templates/sites/${name}.conf.erb`
  template; otherwise `$content` is written verbatim (`site.pp:19-30`). File
  owner/group come from `pick($simp_apache::conf::user/group, ...)`.

- **`simp_apache::validate` (`manifests/validate.pp:6`)** — Not a resource
  class; it just defines `$method_acl`, a nested hash of regex/validation rules
  intended as input to `validate_deep_hash` when managing `ldap`/`limits` ACLs.

### Gotchas / non-obvious details

- **`simp_apache::conf` purges by default.** `$purge` defaults to `true`
  (`conf.pp:95`), which sets `purge`/`force` on `/etc/httpd/conf` and
  `/etc/httpd/conf.d` (`conf.pp:110-113`). Any httpd config file **not** managed
  by this module (or dropped in via `simp_apache::site`) will be removed. This
  is the single most surprising behavior — set `simp_apache::conf::purge: false`
  in Hiera if consumers manage config files out-of-band.
- **The `apache` user/group are hard-pinned to uid/gid 48** (`init.pp:58-102`)
  with `allowdupe => false` — a collision with an existing uid/gid 48 will fail
  the run.
- **The rsync password comes from `simplib::passgen`** (`init.pp:72`), so the
  rsync branch depends on SIMP's passgen infrastructure being available and
  seeded; the server side must accept that generated credential.
- **`$ssl` is read across classes.** `install` gates `mod_ssl` on
  `$simp_apache::ssl` (`install.pp:23`) and `site`/`ssl` read
  `$simp_apache::conf::user`/`group` via `pick(...)` — the component classes are
  tightly coupled through the top-level class's variables, so they are not
  meant to be `include`d standalone in isolation from `simp_apache`.
- **SELinux booleans are only touched when SELinux is enabled** (`init.pp:81`);
  on a `disabled`/absent SELinux host they are silently skipped.
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  every `simplib::lookup('simp_options::*', ...)` call reads that seam
  (`simplib::lookup` is provided by `simp/simplib`). `simp_options` appears only
  as a `.fixtures.yml` fixture for test compilation.
- **This module conflicts with `puppetlabs-apache`** (per `metadata.json`
  summary). Do not attempt to co-manage `httpd` with both.
- **The modules symlink target is arch-gated** (`conf.pp:124-127`); non-`x86_64`
  hosts get `/usr/lib/httpd/modules`.

## The `simp_options` / `simplib::lookup` seam

This is the module's real business-logic seam (the natural target for a
lookup-path unit test). All calls route SIMP feature toggles through
`simplib::lookup('simp_options::*', { 'default_value' => ... })`:

| Location | Key | `default_value` |
|----------|-----|-----------------|
| `init.pp:35` | `simp_options::rsync::server` | `'127.0.0.1'` |
| `init.pp:36` | `simp_options::rsync::timeout` | `2` |
| `install.pp:13-15` | `simp_options::package_ensure` (×3) | `'installed'` |
| `conf.pp:92` | `simp_options::firewall` | `false` |
| `conf.pp:93` | `simp_options::syslog` | `false` |
| `ssl.pp:91` | `simp_options::trusted_nets` | `['127.0.0.1', '::1']` |
| `ssl.pp:92` | `simp_options::openssl::cipher_suite` | `['DEFAULT', '!MEDIUM']` |
| `ssl.pp:97` | `simp_options::pki` | `false` |
| `ssl.pp:98` | `simp_options::pki::source` | `'/etc/pki/simp/x509'` |
| `ssl.pp:105` | `simp_options::firewall` | `false` |
| `ssl.pp:106` | `simp_options::haveged` | `false` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included. There are **no** `simplib::assert_optional_dependency`
calls in this module — every integration (`iptables`, `rsyslog`, `pki`,
`haveged`, `rsync`) is a hard, declared dependency toggled by a `simp_options`
flag.

## Dependencies

Module dependencies (from `metadata.json`) — all hard, no optional dependencies:

- `simp/simplib` `>= 4.9.0 < 5.0.0` (provides `simplib::lookup`,
  `simplib::assert_metadata`, `simplib::passgen`, `simplib::nets2cidr`, and the
  `Simplib::*` data types used throughout)
- `simp/haveged` `>= 0.4.5 < 1.0.0` (entropy, via the SSL class)
- `simp/iptables` `>= 6.5.3 < 8.0.0` (firewall rules)
- `simp/logrotate` `>= 6.5.0 < 7.0.0`
- `simp/pki` `>= 6.2.0 < 7.0.0` (`pki::copy` for certs)
- `simp/rsync` `>= 6.1.1 < 7.0.0` (web-root sync)
- `simp/rsyslog` `>= 7.6.0 < 9.0.0` (log routing)
- `simp/auditd` `>= 8.5.0 < 9.0.0`
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (`pick()` and friends)

Runtime requirement (from `metadata.json` `requirements`): `puppet
>= 7.0.0 < 9.0.0`. (SIMP is migrating Puppet → OpenVox; this module still names
`puppet` and its `Gemfile` installs only the `puppet` gem. When `metadata.json`
switches this to `openvox`, update this line to match.)

Supported OS matrix (from `metadata.json`): CentOS 7/8/9; RedHat 7/8/9;
OracleLinux 7/8/9; Rocky 8/9; AlmaLinux 8/9.

## Repository layout

- `manifests/init.pp` — `simp_apache`, the orchestrating entry class.
- `manifests/install.pp` — `simp_apache::install` (private): packages.
- `manifests/conf.pp` — `simp_apache::conf`: `httpd.conf`, dirs, symlinks,
  firewall/syslog branches; carries most tunables.
- `manifests/service.pp` — `simp_apache::service`: the `httpd` service.
- `manifests/ssl.pp` — `simp_apache::ssl`: `ssl.conf`, PKI, haveged, HTTPS
  firewall.
- `manifests/site.pp` — `simp_apache::site` **define**: per-site vhost configs.
- `manifests/validate.pp` — `simp_apache::validate`: the `$method_acl`
  validation-rule hash (no resources).
- `types/logseverity.pp` — `Simp_apache::LogSeverity`, an `Enum` of Apache log
  levels used by `conf.pp`.
- `lib/facter/apache_version.rb` — custom fact `apache_version` (parses
  `apachectl -v`; returns `'unknown'` if undeterminable).
- `lib/puppet/type/htaccess.rb` + `lib/puppet/provider/htaccess/htaccess.rb` —
  custom `htaccess` type/provider managing htpasswd-style files (namevar is
  `path:username`).
- `lib/puppet/functions/simp_apache/` — three Ruby v4 functions: `auth`
  (builds Apache auth directives from a hash), `limits` (builds `Limit`/`Order`
  ACL directives), and `munge_httpd_networks` (normalizes networks to Apache
  form, e.g. `0.0.0.0/0` → `ALL`).
- `templates/etc/httpd/conf/httpd.conf.erb`, `.../conf.d/ssl.conf.erb`,
  `.../conf/magic.epp` — the config templates.
- `metadata.json` — deps, OS matrix, Puppet requirement.
- `spec/classes/{init,conf,ssl}_spec.rb`, `spec/defines/site_spec.rb` —
  rspec-puppet unit tests; `spec/classes/expected/httpd.conf_default_el{7,8,9}`
  are golden-file comparisons of the rendered `httpd.conf`.
- `spec/functions/simp_apache/*_spec.rb`, `spec/unit/puppet/{type,provider}/` —
  unit tests for the functions and the `htaccess` type/provider.
- `spec/acceptance/suites/{default,htaccess}/` — beaker suites;
  `spec/acceptance/nodesets/{default,oel}.yml` — nodesets.
- **No `data/` or `hiera.yaml`** — this module ships no module-level Hiera data;
  all defaults are inline in the manifests.
- **Acceptance does NOT run in CI:** `.github/workflows/pr_tests.yml` has six
  jobs only — `puppet-syntax`, `puppet-style`, `ruby-style`, `file-checks`,
  `releng-checks`, and `spec-tests` (a Puppet-version matrix). There is no
  `acceptance`/beaker job and no `BEAKER_HYPERVISOR` in CI; the nodesets exist
  for **local** acceptance runs only.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single spec
bundle exec rspec spec/classes/init_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite (local only — not run in CI)
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-rspec-puppet-facts ~> 4.0.0`,
`simp-beaker-helpers ~> 2.0.0`. Rubocop is pinned to `~> 1.88.0`. The `Gemfile`
defaults `puppet_version` to `['>= 7', '< 9']` and installs the `puppet` gem
(no `openvox` gem). `spec/spec_helper.rb` requires
`puppetlabs_spec_helper/module_spec_helper`.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on the classes,
  the define, and the functions — they drive `REFERENCE.md`. Regenerate
  `REFERENCE.md` after changing docs or parameters.
- Keep routing SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })` with an
  explicit default rather than assuming `simp_options` is included.
- Keep `simp_apache::install` `assert_private()`'d — it is an implementation
  detail of `simp_apache`, not a public entry point.
- Respect the component-class coupling: `install`/`conf`/`service`/`ssl` read
  top-level `simp_apache` variables and each other's params — declare them via
  the `simp_apache` orchestration, not standalone.
- Be careful with `simp_apache::conf::purge` (default `true`): new config files
  must be managed by the module (or `simp_apache::site`) or they will be purged.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry a
  **puppetsync** notice — they are baseline-managed and the next sync overwrites
  local edits. Push changes to those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow / aligned-`=`
  parameter style used across `manifests/`.
- This is a legacy module intended to eventually migrate to `puppetlabs-apache`
  (`init.pp:6-7`) — favor minimal, targeted fixes over large refactors.
