<script lang="ts">
  import { browser } from '$app/environment';

  type Note = {
    id: string;
    title: string;
    body: string;
    tag: string;
    pinned: boolean;
    updatedAt: number;
  };

  const storageKey = 'sveltekit-notes.items';
  const now = Date.now();
  const starterNotes: Note[] = [
    {
      id: cryptoSafeId(),
      title: 'Trip ideas',
      body: 'Train routes, small museums, one very good bakery near the station.',
      tag: 'Personal',
      pinned: true,
      updatedAt: now - 1000 * 60 * 18
    },
    {
      id: cryptoSafeId(),
      title: 'Project standup',
      body: 'Ship the draft flow, tighten empty states, and check the mobile editor.',
      tag: 'Work',
      pinned: false,
      updatedAt: now - 1000 * 60 * 72
    },
    {
      id: cryptoSafeId(),
      title: 'Books to find',
      body: 'Essays, field guides, and something short enough for a rainy evening.',
      tag: 'Reading',
      pinned: false,
      updatedAt: now - 1000 * 60 * 220
    }
  ];

  let notes = $state<Note[]>(starterNotes);
  let activeId = $state(starterNotes[0].id);
  let query = $state('');

  const filteredNotes = $derived(
    notes
      .filter((note) => {
        const haystack = `${note.title} ${note.body} ${note.tag}`.toLowerCase();
        return haystack.includes(query.trim().toLowerCase());
      })
      .sort((a, b) => Number(b.pinned) - Number(a.pinned) || b.updatedAt - a.updatedAt)
  );

  const activeNote = $derived(notes.find((note) => note.id === activeId) ?? filteredNotes[0] ?? notes[0]);
  const noteCountLabel = $derived(`${notes.length} ${notes.length === 1 ? 'note' : 'notes'}`);

  $effect(() => {
    if (!browser) return;

    const saved = localStorage.getItem(storageKey);
    if (!saved) return;

    try {
      const parsed = JSON.parse(saved) as Note[];
      if (Array.isArray(parsed) && parsed.length > 0) {
        notes = parsed;
        activeId = parsed[0].id;
      }
    } catch {
      localStorage.removeItem(storageKey);
    }
  });

  $effect(() => {
    if (browser) {
      localStorage.setItem(storageKey, JSON.stringify(notes));
    }
  });

  function cryptoSafeId() {
    if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
      return crypto.randomUUID();
    }

    return `note-${Math.random().toString(36).slice(2)}`;
  }

  function createNote() {
    const note: Note = {
      id: cryptoSafeId(),
      title: 'Untitled note',
      body: '',
      tag: 'Inbox',
      pinned: false,
      updatedAt: Date.now()
    };

    notes = [note, ...notes];
    activeId = note.id;
    query = '';
  }

  function updateActiveNote(field: 'title' | 'body' | 'tag', value: string) {
    if (!activeNote) return;

    notes = notes.map((note) =>
      note.id === activeNote.id ? { ...note, [field]: value, updatedAt: Date.now() } : note
    );
  }

  function togglePinned() {
    if (!activeNote) return;

    notes = notes.map((note) =>
      note.id === activeNote.id
        ? { ...note, pinned: !note.pinned, updatedAt: Date.now() }
        : note
    );
  }

  function deleteActiveNote() {
    if (!activeNote) return;

    const remaining = notes.filter((note) => note.id !== activeNote.id);
    notes = remaining;
    activeId = remaining[0]?.id ?? '';
  }

  function formatUpdated(timestamp: number) {
    return new Intl.DateTimeFormat(undefined, {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    }).format(timestamp);
  }
</script>

<svelte:head>
  <title>Notes</title>
  <meta name="description" content="A simple local note-taking app built with SvelteKit." />
</svelte:head>

<main class="workspace">
  <section class="sidebar" aria-label="Notes">
    <header class="sidebar-header">
      <div>
        <p class="eyebrow">{noteCountLabel}</p>
        <h1>Notes</h1>
      </div>
      <button class="icon-button primary" aria-label="Create note" title="Create note" onclick={createNote}>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M12 5v14M5 12h14" />
        </svg>
      </button>
    </header>

    <label class="search">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="11" cy="11" r="7" />
        <path d="m16 16 4 4" />
      </svg>
      <input bind:value={query} type="search" aria-label="Search notes" placeholder="Search" />
    </label>

    <div class="note-list">
      {#each filteredNotes as note}
        <button
          class:active={activeNote?.id === note.id}
          class="note-row"
          type="button"
          onclick={() => (activeId = note.id)}
        >
          <span class="note-row-top">
            <span class="note-title">{note.title || 'Untitled note'}</span>
            {#if note.pinned}
              <span class="pin-dot" aria-label="Pinned"></span>
            {/if}
          </span>
          <span class="note-preview">{note.body || 'No content yet'}</span>
          <span class="note-meta">
            <span>{note.tag || 'Inbox'}</span>
            <span>{formatUpdated(note.updatedAt)}</span>
          </span>
        </button>
      {:else}
        <div class="empty-list">
          <strong>No matches</strong>
          <span>Try a different search.</span>
        </div>
      {/each}
    </div>
  </section>

  <section class="editor" aria-label="Editor">
    {#if activeNote}
      <div class="editor-toolbar">
        <input
          class="tag-input"
          aria-label="Note tag"
          value={activeNote.tag}
          oninput={(event) => updateActiveNote('tag', event.currentTarget.value)}
        />
        <div class="tool-actions">
          <button
            class:pressed={activeNote.pinned}
            class="icon-button"
            aria-label={activeNote.pinned ? 'Unpin note' : 'Pin note'}
            title={activeNote.pinned ? 'Unpin note' : 'Pin note'}
            onclick={togglePinned}
          >
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="m15 4 5 5-4 4v5l-1 1-4-4-5 5-2-2 5-5-4-4 1-1h5z" />
            </svg>
          </button>
          <button class="icon-button danger" aria-label="Delete note" title="Delete note" onclick={deleteActiveNote}>
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3" />
            </svg>
          </button>
        </div>
      </div>

      <input
        class="title-input"
        aria-label="Note title"
        value={activeNote.title}
        oninput={(event) => updateActiveNote('title', event.currentTarget.value)}
      />

      <textarea
        aria-label="Note body"
        value={activeNote.body}
        oninput={(event) => updateActiveNote('body', event.currentTarget.value)}
        placeholder="Start writing..."
      ></textarea>
    {:else}
      <div class="empty-editor">
        <h2>No note selected</h2>
        <button class="create-button" type="button" onclick={createNote}>Create note</button>
      </div>
    {/if}
  </section>
</main>

<style>
  .workspace {
    display: grid;
    grid-template-columns: minmax(18rem, 24rem) minmax(0, 1fr);
    gap: 0;
    width: min(1180px, calc(100vw - 32px));
    min-height: calc(100vh - 32px);
    margin: 16px auto;
    overflow: hidden;
    border: 1px solid rgba(37, 49, 46, 0.14);
    border-radius: 8px;
    background: rgba(255, 252, 245, 0.78);
    box-shadow: 0 24px 70px rgba(37, 49, 46, 0.12);
    backdrop-filter: blur(18px);
  }

  .sidebar {
    display: flex;
    min-height: 0;
    flex-direction: column;
    border-right: 1px solid rgba(37, 49, 46, 0.12);
    background: rgba(249, 245, 235, 0.86);
  }

  .sidebar-header,
  .editor-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }

  .sidebar-header {
    padding: 24px 22px 14px;
  }

  .eyebrow {
    margin: 0 0 4px;
    color: #6d776f;
    font-size: 0.78rem;
    font-weight: 700;
    text-transform: uppercase;
  }

  h1 {
    margin: 0;
    font-size: clamp(2rem, 5vw, 3.9rem);
    line-height: 0.96;
    letter-spacing: 0;
  }

  .icon-button {
    display: inline-grid;
    width: 2.55rem;
    height: 2.55rem;
    flex: 0 0 auto;
    place-items: center;
    border: 1px solid rgba(37, 49, 46, 0.18);
    border-radius: 8px;
    background: #fffaf0;
    cursor: pointer;
    transition:
      transform 160ms ease,
      border-color 160ms ease,
      background 160ms ease;
  }

  .icon-button:hover {
    transform: translateY(-1px);
    border-color: rgba(37, 49, 46, 0.34);
  }

  .icon-button.primary,
  .icon-button.pressed {
    border-color: #37675c;
    background: #37675c;
    color: #fffaf0;
  }

  .icon-button.danger:hover {
    border-color: #a34f45;
    color: #8f352b;
  }

  .icon-button svg,
  .search svg {
    width: 1.15rem;
    height: 1.15rem;
    fill: none;
    stroke: currentColor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 2;
  }

  .search {
    display: flex;
    align-items: center;
    gap: 10px;
    margin: 0 22px 14px;
    padding: 0 13px;
    border: 1px solid rgba(37, 49, 46, 0.14);
    border-radius: 8px;
    background: rgba(255, 250, 240, 0.82);
    color: #5e6a63;
  }

  .search input {
    width: 100%;
    min-width: 0;
    height: 2.75rem;
    border: 0;
    background: transparent;
    color: #25312e;
  }

  .search input:focus {
    outline: 0;
  }

  .note-list {
    display: grid;
    gap: 8px;
    min-height: 0;
    padding: 0 14px 14px;
    overflow: auto;
  }

  .note-row {
    display: grid;
    gap: 7px;
    width: 100%;
    min-height: 8.3rem;
    padding: 15px;
    border: 1px solid transparent;
    border-radius: 8px;
    background: transparent;
    text-align: left;
    cursor: pointer;
  }

  .note-row:hover,
  .note-row.active {
    border-color: rgba(37, 49, 46, 0.12);
    background: #fffaf0;
  }

  .note-row.active {
    box-shadow: inset 4px 0 0 #d8b25f;
  }

  .note-row-top,
  .note-meta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
  }

  .note-title {
    overflow: hidden;
    font-size: 1rem;
    font-weight: 800;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .pin-dot {
    width: 0.52rem;
    height: 0.52rem;
    flex: 0 0 auto;
    border-radius: 999px;
    background: #d8b25f;
  }

  .note-preview {
    display: -webkit-box;
    overflow: hidden;
    min-height: 2.9rem;
    color: #59645f;
    font-size: 0.9rem;
    line-height: 1.55;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
  }

  .note-meta {
    color: #7f867e;
    font-size: 0.78rem;
    font-weight: 700;
  }

  .editor {
    display: grid;
    grid-template-rows: auto auto 1fr;
    min-width: 0;
    min-height: 0;
    padding: 24px;
    background:
      linear-gradient(rgba(255, 250, 240, 0.88), rgba(255, 250, 240, 0.88)),
      repeating-linear-gradient(0deg, transparent 0 35px, rgba(37, 49, 46, 0.08) 36px);
  }

  .editor-toolbar {
    margin-bottom: 22px;
  }

  .tool-actions {
    display: flex;
    gap: 8px;
  }

  .tag-input {
    width: min(14rem, 50vw);
    height: 2.45rem;
    padding: 0 12px;
    border: 1px solid rgba(37, 49, 46, 0.18);
    border-radius: 8px;
    background: rgba(255, 250, 240, 0.82);
    color: #37675c;
    font-size: 0.88rem;
    font-weight: 800;
  }

  .title-input,
  textarea {
    width: 100%;
    min-width: 0;
    border: 0;
    background: transparent;
    color: #25312e;
  }

  .title-input {
    margin-bottom: 18px;
    font-size: clamp(2.1rem, 8vw, 5.4rem);
    font-weight: 850;
    line-height: 0.98;
    letter-spacing: 0;
  }

  .title-input:focus,
  textarea:focus {
    outline: 0;
  }

  textarea {
    min-height: 0;
    resize: none;
    color: #39433f;
    font-size: 1.08rem;
    line-height: 1.7;
  }

  .empty-list,
  .empty-editor {
    display: grid;
    place-items: center;
    align-content: center;
    gap: 8px;
    min-height: 12rem;
    color: #6d776f;
    text-align: center;
  }

  .empty-editor {
    min-height: 60vh;
  }

  .empty-editor h2 {
    margin: 0;
    color: #25312e;
  }

  .create-button {
    min-height: 2.6rem;
    padding: 0 16px;
    border: 1px solid #37675c;
    border-radius: 8px;
    background: #37675c;
    color: #fffaf0;
    cursor: pointer;
  }

  @media (max-width: 760px) {
    .workspace {
      grid-template-columns: 1fr;
      width: 100%;
      min-height: 100vh;
      margin: 0;
      border-width: 0;
      border-radius: 0;
    }

    .sidebar {
      max-height: 45vh;
      border-right: 0;
      border-bottom: 1px solid rgba(37, 49, 46, 0.12);
    }

    .sidebar-header {
      padding: 18px 16px 12px;
    }

    .search {
      margin-inline: 16px;
    }

    .note-list {
      grid-auto-flow: column;
      grid-auto-columns: minmax(15rem, 78vw);
      padding-inline: 16px;
      overflow-x: auto;
    }

    .note-row {
      min-height: 8rem;
    }

    .editor {
      min-height: 55vh;
      padding: 18px 16px 24px;
    }
  }
</style>
