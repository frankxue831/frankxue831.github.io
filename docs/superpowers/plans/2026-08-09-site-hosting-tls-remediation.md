# Site Hosting and TLS Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore a certificate-valid apex domain, preserve every apex path and query in one canonical redirect to `www`, and close the two hosting observations with reproducible live evidence.

**Architecture:** Keep GitHub Pages and `www.frankxue.dev` as the canonical site. Point the apex directly at GitHub Pages with the current official `A` and `AAAA` records, retain the existing `www` CNAME, remove conflicting apex records, wait for GitHub Pages certificate provisioning, and verify from the public internet before changing Notion. This workstream is operational; it should not modify the repository.

**Tech Stack:** Authoritative DNS, GitHub Pages custom domains, TLS/SAN inspection with OpenSSL, `dig`, `curl`, GitHub Pages documentation, and the connected Notion issue database.

## Global Constraints

- This is a separately authorized infrastructure change. DNS writes require access to the authoritative DNS account for `frankxue.dev`; do not substitute registrar forwarding, an HTTP redirect service, or a new proxy.
- Keep `/Users/fengxiang/Desktop/agent_workspace/frankxue831.github.io/CNAME` equal to `www.frankxue.dev` and keep `www.frankxue.dev` as the canonical Pages domain.
- Re-read the current official GitHub Pages custom-domain documentation immediately before changing DNS. If its published endpoints differ from this plan, stop and revise the record set before writing.
- Do not close the certificate issue on the strength of DNS propagation alone. Strict TLS, SAN coverage, canonical redirects, paths, and queries must all pass.
- Do not change the repository, create an empty commit, or edit the 72 `info` rows.
- Run shell commands from `/Users/fengxiang/Desktop/agent_workspace/frankxue831.github.io`.
- Use UTC timestamps in the verification record and Notion resolution.

---

### Task 1: Capture the pre-change DNS and live-site baseline

**Files:**
- Read: `CNAME`
- No repository files modified

**Interfaces:**
- Reads: authoritative DNS answers and the certificate served for `frankxue.dev`.
- Produces: a timestamped before-state that prevents changing the wrong zone and documents the existing path-preserving redirect.

- [ ] **Step 1: Confirm the repository domain declaration**

Run:

```bash
git status --short --branch
cat CNAME
```

Expected: the worktree is clean and `CNAME` prints exactly `www.frankxue.dev`.

- [ ] **Step 2: Identify the authoritative nameservers and current records**

Run:

```bash
date -u '+%Y-%m-%dT%H:%M:%SZ'
dig +short NS frankxue.dev
dig +short A frankxue.dev
dig +short AAAA frankxue.dev
dig +short CNAME www.frankxue.dev
```

Record every answer verbatim. The current defect is expected to include apex answers outside the GitHub Pages endpoint set; `www` should resolve through `frankxue831.github.io`.

- [ ] **Step 3: Prove the certificate defect without bypassing validation**

Run:

```bash
curl --fail --silent --show-error --head https://frankxue.dev/
openssl s_client -connect frankxue.dev:443 -servername frankxue.dev </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
```

Expected before repair: strict `curl` fails certificate-name validation, and the SAN output does not contain `DNS:frankxue.dev`.

- [ ] **Step 4: Preserve evidence that the old deep-path observation is already resolved**

Run the diagnostic requests with `-k` only because Task 1 is documenting the known certificate fault:

```bash
curl -k --silent --show-error --location --output /dev/null --write-out 'root code=%{http_code} redirects=%{num_redirects} final=%{url_effective}\n' https://frankxue.dev/
curl -k --silent --show-error --location --output /dev/null --write-out 'projects code=%{http_code} redirects=%{num_redirects} final=%{url_effective}\n' https://frankxue.dev/projects/
curl -k --silent --show-error --location --output /dev/null --write-out 'zh-query code=%{http_code} redirects=%{num_redirects} final=%{url_effective}\n' 'https://frankxue.dev/zh/?from=apex'
```

Expected: each request returns `code=200`, `redirects=1`, and a final URL on `https://www.frankxue.dev` with the original path and query intact.

- [ ] **Step 5: Save the baseline in the execution log**

The execution log must contain the UTC timestamp, NS/A/AAAA/CNAME answers, certificate SAN output, all three redirect summaries, and the statement: `Diagnostic -k was used only to isolate redirect behavior from the known SAN failure.` Do not commit this log to the site unless the user explicitly asks for an infrastructure record in the repository.

---

### Task 2: Replace the apex detour with GitHub Pages DNS records

**Files:**
- No repository files modified

**Interfaces:**
- Writes: the authoritative DNS zone for `frankxue.dev`.
- Preserves: `www.frankxue.dev CNAME frankxue831.github.io`.
- Removes: apex records that conflict with the GitHub Pages endpoint set.

- [ ] **Step 1: Re-read the official endpoint list**

Open and verify the apex values in:

```text
https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site
```

As of 2026-08-09 the documented record set is:

```text
@  A     185.199.108.153
@  A     185.199.109.153
@  A     185.199.110.153
@  A     185.199.111.153
@  AAAA  2606:50c0:8000::153
@  AAAA  2606:50c0:8001::153
@  AAAA  2606:50c0:8002::153
@  AAAA  2606:50c0:8003::153
www CNAME frankxue831.github.io.
```

If GitHub's current documentation differs, use the current documented values and record that divergence in the execution log.

- [ ] **Step 2: Resolve the exact zone and obtain change authority**

Confirm that the account being used controls the nameservers returned in Task 1. If DNS access is unavailable, stop this task without altering Notion; deliver the exact record set and acceptance commands to the user.

- [ ] **Step 3: Apply one bounded zone change**

At the authoritative provider:

1. Remove all conflicting apex `A`, `AAAA`, `CNAME`, forwarding, flattening, or ALIAS records that lead to the AWS detour.
2. Add the four GitHub Pages `A` records.
3. Add the four GitHub Pages `AAAA` records.
4. Preserve `www CNAME frankxue831.github.io.`
5. Preserve unrelated MX, TXT, CAA, and subdomain records.
6. Use the provider's existing TTL or 300 seconds; do not lengthen TTL during the repair.

- [ ] **Step 4: Read the zone back from the provider**

Before leaving the provider UI/API, verify that the saved apex set contains exactly the intended GitHub Pages `A`/`AAAA` answers and no conflicting apex routing record. Capture a provider-generated change identifier or screenshot reference in the execution log.

---

### Task 3: Wait for public DNS and GitHub Pages certificate convergence

**Files:**
- No repository files modified

**Interfaces:**
- Reads: multiple public DNS resolvers and the live TLS endpoint.
- Produces: the go/no-go evidence for closing the TLS row.

- [ ] **Step 1: Verify authoritative and public resolver answers**

Run periodically, without making further DNS changes while TTLs are converging:

```bash
dig +short A frankxue.dev
dig +short AAAA frankxue.dev
dig @1.1.1.1 +short A frankxue.dev
dig @1.1.1.1 +short AAAA frankxue.dev
dig @8.8.8.8 +short A frankxue.dev
dig @8.8.8.8 +short AAAA frankxue.dev
dig +short CNAME www.frankxue.dev
```

Expected: all resolvers converge on the four documented IPv4 and four documented IPv6 values; `www` resolves through `frankxue831.github.io`.

- [ ] **Step 2: Wait for a SAN-valid certificate**

Run:

```bash
openssl s_client -connect frankxue.dev:443 -servername frankxue.dev </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
```

Expected: SAN contains `DNS:frankxue.dev`, and the certificate is currently valid. DNS success without this SAN is not completion.

- [ ] **Step 3: Run the strict HTTPS acceptance matrix**

Do not use `-k`:

```bash
curl --fail --silent --show-error --location --output /dev/null --write-out 'root code=%{http_code} redirects=%{num_redirects} final=%{url_effective}\n' https://frankxue.dev/
curl --fail --silent --show-error --location --output /dev/null --write-out 'projects code=%{http_code} redirects=%{num_redirects} final=%{url_effective}\n' https://frankxue.dev/projects/
curl --fail --silent --show-error --location --output /dev/null --write-out 'zh-query code=%{http_code} redirects=%{num_redirects} final=%{url_effective}\n' 'https://frankxue.dev/zh/?from=apex'
curl --fail --silent --show-error --location --output /dev/null --write-out 'http-root code=%{http_code} redirects=%{num_redirects} final=%{url_effective}\n' http://frankxue.dev/
curl --fail --silent --show-error --head https://www.frankxue.dev/404.html
```

Expected:

- the three apex HTTPS requests end at the matching `www` path/query with `code=200` and `redirects=1`;
- HTTP apex reaches canonical HTTPS without an intermediate AWS error page;
- the shared `www` 404 document remains reachable with `200`.

- [ ] **Step 4: Check for routing regression without TLS bypass**

Run:

```bash
curl --silent --show-error --location https://frankxue.dev/projects/ | rg -n "<title>|AWS|NoSuchBucket|AccessDenied"
curl --silent --show-error --location 'https://frankxue.dev/zh/?from=apex' | rg -n "<html lang=|AWS|NoSuchBucket|AccessDenied"
```

Expected: the intended site title/language is present and no AWS error signature appears.

---

### Task 4: Resolve the two hosting rows in Notion

**Files:**
- No repository files modified

**Interfaces:**
- Updates database: `Site review issues — 2026-08-03 continuous`.
- Deep-path row ID: `3b1a01fc-cd2b-814d-b787-fe4b0d77f81d`.
- Certificate row ID: `3b7a01fc-cd2b-81ae-9ef9-fce72058e8cb`.

- [ ] **Step 1: Re-fetch both rows**

Fetch both row IDs immediately before updating. Confirm each is still open and still belongs to the `frankxue.dev — personal site` project. If either row's scope or acceptance condition changed, stop and re-triage it.

- [ ] **Step 2: Resolve the historical deep-path row from evidence**

Run `date -u '+%Y-%m-%dT%H:%M:%SZ'`. Start the resolution with `Resolution — ` followed by that exact output, append the three literal lines below, and then paste the exact redirect command output captured in Tasks 1 and 3:

```text
Disposition: already resolved in the current live routing; no repository change was required.
Evidence: strict public requests to /, /projects/, and /zh/?from=apex each preserve path/query, redirect once to the matching www URL, and finish with HTTP 200. The pre-change diagnostic showed the same redirect behavior behind the separate SAN defect.
Verification: curl redirect summaries attached below.
```

Set status to `fixed-mid-session`. Do not claim the DNS change caused this already-working path behavior.

- [ ] **Step 3: Resolve the certificate row only after every strict check passes**

Start the resolution with `Resolution — ` followed by the same actual UTC output, append the three literal lines below, and then paste the verified DNS answers, SAN output, and strict redirect summaries:

```text
Disposition: fixed by replacing the conflicting apex detour with the current GitHub Pages apex A/AAAA set while retaining www CNAME frankxue831.github.io.
Evidence: public resolvers return the documented Pages endpoints; the live certificate SAN contains frankxue.dev; strict curl succeeds without -k; root, /projects/, and /zh/?from=apex preserve path/query in one canonical redirect and finish with HTTP 200.
Verification: DNS answers, certificate SAN output, and strict redirect summaries attached below.
```

Set status to `fixed-mid-session`.

- [ ] **Step 4: Audit the final operational state**

Re-fetch both rows and confirm the resolutions are appended, statuses are correct, and no `info` row was modified. Run `git status --short`; expected output is empty because this workstream has no repository changes.
