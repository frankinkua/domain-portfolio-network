# Domain Portfolio Placeholder (`frankinkua.github.io`)

User-level GitHub Pages repository serving a uniform, zero-data **"Work in Progress"** landing page across all delegated portfolio domains.

## Architecture

- **Root GitHub Pages (`frankinkua.github.io`):** Serves `index.html` and `404.html` directly at `/` with zero domain/owner metadata or external data dependencies.
- **Edge Routing:** Portfolio zones on Cloudflare proxy `@` and `www` (`CNAME -> dd6f0a19-2dde-42ed-bfad-295b586b461f.cfargotunnel.com`) which rewrites the origin `Host` header to `frankinkua.github.io` over HTTPS, allowing unlimited custom domains to resolve cleanly with HTTP 200 and Universal SSL.
