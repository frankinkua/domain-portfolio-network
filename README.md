# Domain Portfolio Network

Headless, multi-tenant landing engine powering Frank's 300+ domain portfolio on GitHub Pages, backed by Cloudflare DNS and edge acceleration.

## Architecture

- **Multi-Tenant Router:** `index.html` inspects `window.location.hostname` dynamically, mapping it to vertical metadata from `domains.json` in sub-10ms with zero server cost.
- **Edge Routing:** Cloudflare zones proxy traffic (`CNAME @ -> frankinkua.github.io`) with SSL/TLS edge encryption.
- **Registrar:** Delegated via united-domains customer portal.

## Vertical Catalog

- **German Cannabis & Lifestyle:** Cannabis Social Clubs, dispensary guides, regional culture.
- **AI & Advanced Robotics:** Edge intelligence, swarm nodes, physical autonomy showcase.
- **Education & Career Archives:** Aged youth archives (`azubiarchiv.de`, `studentenarchiv.de`, etc.).
- **Metaverse & Web3:** Spatial computing, virtual platforms.
- **Mobility & Transit:** Ride coordination, transport services.
- **Interactive Media:** Soundtracks, audio synthesis, video hubs.
