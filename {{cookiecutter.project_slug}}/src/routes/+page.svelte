<script>
  let identity = $state(null);
  let loaded = $state(false);

  // App Service EasyAuth exposes the signed-in principal at /.auth/me.
  // Until EasyAuth is enabled this 404s / returns empty — handled gracefully.
  async function loadIdentity() {
    try {
      const res = await fetch('/.auth/me');
      if (res.ok) {
        const data = await res.json();
        identity = (Array.isArray(data) ? data[0] : data?.clientPrincipal) ?? null;
      }
    } catch (_) { /* not authenticated / EasyAuth off */ }
    loaded = true;
  }
  $effect(() => { loadIdentity(); });
</script>

<main>
  <div class="card">
    <div class="badge">dev · Azure App Service</div>
    <h1>Your App</h1>
    <p class="sub">Your Azure project — running on the platform you built.</p>

    <section class="identity">
      <h2>Identity</h2>
      {#if !loaded}
        <p class="muted">checking…</p>
      {:else if identity}
        <p class="ok">✓ Signed in as <strong>{identity.userDetails ?? identity.user_id ?? 'unknown'}</strong></p>
        <ul>
          {#each (identity.userClaims ?? identity.claims ?? []) as c}
            <li><span>{c.typ?.split('/').pop() ?? c.typ}</span>{c.val}</li>
          {/each}
        </ul>
      {:else}
        <p class="muted">Not signed in (Entra EasyAuth not enabled yet).</p>
      {/if}
    </section>

    <a class="health" href="/health">health check →</a>
  </div>
</main>

<style>
  :global(body) { margin: 0; background: oklch(18% 0.03 264); color: oklch(92% 0.02 264);
    font-family: 'Segoe UI', system-ui, sans-serif; }
  main { min-height: 100vh; display: grid; place-items: center; padding: 2rem; }
  .card { width: min(560px, 100%); background: oklch(23% 0.035 264);
    border: 1px solid oklch(34% 0.04 264); border-radius: 18px; padding: 2.5rem; }
  .badge { display: inline-block; font-size: .8rem; font-weight: 600; letter-spacing: .04em;
    color: oklch(80% 0.13 200); background: oklch(28% 0.06 200); padding: .35rem .7rem;
    border-radius: 999px; }
  h1 { font-size: 2.6rem; margin: 1rem 0 .3rem; letter-spacing: -.02em;
    background: linear-gradient(90deg, oklch(80% 0.15 200), oklch(75% 0.15 300));
    -webkit-background-clip: text; background-clip: text; color: transparent; }
  .sub { color: oklch(70% 0.02 264); margin: 0 0 2rem; }
  .identity { border-top: 1px solid oklch(34% 0.04 264); padding-top: 1.5rem; }
  h2 { font-size: 1rem; text-transform: uppercase; letter-spacing: .08em;
    color: oklch(65% 0.02 264); margin: 0 0 .8rem; }
  .ok { color: oklch(80% 0.15 150); }
  .muted { color: oklch(58% 0.02 264); }
  ul { list-style: none; padding: 0; margin: .8rem 0 0; font-size: .85rem; }
  li { display: flex; gap: .6rem; padding: .35rem 0; border-bottom: 1px solid oklch(28% 0.03 264); }
  li span { color: oklch(70% 0.13 300); min-width: 140px; font-weight: 600; }
  .health { display: inline-block; margin-top: 2rem; color: oklch(80% 0.13 200);
    text-decoration: none; font-size: .9rem; }
  .health:hover { text-decoration: underline; }
</style>
