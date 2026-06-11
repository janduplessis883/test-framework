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

<main
  class="mx-auto grid min-h-dvh w-full overflow-hidden border-[#25312e24] bg-[#fffcf5c7] text-[#25312e] shadow-[0_24px_70px_rgba(37,49,46,0.12)] backdrop-blur-xl md:my-4 md:min-h-[calc(100vh-2rem)] md:w-[min(1180px,calc(100vw-2rem))] md:grid-cols-[minmax(18rem,24rem)_minmax(0,1fr)] md:rounded-lg md:border"
>
  <section
    class="flex min-h-0 max-h-[45dvh] flex-col border-b border-[#25312e1f] bg-[#f9f5ebdb] md:max-h-none md:border-r md:border-b-0"
    aria-label="Notes"
  >
    <header class="flex items-center justify-between gap-4 px-4 pt-4 pb-3 md:px-5 md:pt-6 md:pb-3.5">
      <div>
        <p class="mb-1 text-xs font-bold text-[#6d776f] uppercase">{noteCountLabel}</p>
        <h1 class="text-[clamp(2rem,12vw,3.9rem)] leading-none font-black tracking-normal md:text-[clamp(2rem,5vw,3.9rem)]">Notes</h1>
      </div>
      <button
        class="grid size-11 shrink-0 cursor-pointer place-items-center rounded-lg border border-[#37675c] bg-[#37675c] text-[#fffaf0] transition hover:-translate-y-0.5 hover:border-[#25312e57] md:size-10"
        aria-label="Create note"
        title="Create note"
        onclick={createNote}
      >
        <svg class="size-5 fill-none stroke-current stroke-2" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M12 5v14M5 12h14" />
        </svg>
      </button>
    </header>

    <label
      class="mx-4 mb-3 flex items-center gap-2.5 rounded-lg border border-[#25312e24] bg-[#fffaf0d1] px-3 text-[#5e6a63] md:mx-5 md:mb-3.5"
    >
      <svg class="size-5 fill-none stroke-current stroke-2" viewBox="0 0 24 24" aria-hidden="true">
        <circle cx="11" cy="11" r="7" />
        <path d="m16 16 4 4" />
      </svg>
      <input
        class="h-12 w-full min-w-0 border-0 bg-transparent text-[#25312e] outline-none md:h-11"
        bind:value={query}
        type="search"
        aria-label="Search notes"
        placeholder="Search"
      />
    </label>

    <div
      class="grid min-h-0 auto-cols-[minmax(15rem,78vw)] grid-flow-col gap-2 overflow-x-auto px-4 pb-4 md:grid-flow-row md:auto-cols-auto md:overflow-auto md:px-3.5"
    >
      {#each filteredNotes as note}
        <button
          class={[
            'grid min-h-32 w-full cursor-pointer gap-2 rounded-lg border p-4 text-left transition hover:border-[#25312e1f] hover:bg-[#fffaf0]',
            activeNote?.id === note.id
              ? 'border-[#25312e1f] bg-[#fffaf0] shadow-[inset_4px_0_0_#d8b25f]'
              : 'border-transparent bg-transparent'
          ]}
          type="button"
          onclick={() => (activeId = note.id)}
        >
          <span class="flex items-center justify-between gap-2.5">
            <span class="truncate text-base font-extrabold">{note.title || 'Untitled note'}</span>
            {#if note.pinned}
              <span class="size-2 shrink-0 rounded-full bg-[#d8b25f]" aria-label="Pinned"></span>
            {/if}
          </span>
          <span class="line-clamp-2 min-h-11 overflow-hidden text-sm leading-6 text-[#59645f]">{note.body || 'No content yet'}</span>
          <span class="flex items-center justify-between gap-2.5 text-xs font-bold text-[#7f867e]">
            <span>{note.tag || 'Inbox'}</span>
            <span>{formatUpdated(note.updatedAt)}</span>
          </span>
        </button>
      {:else}
        <div class="grid min-h-48 place-items-center content-center gap-2 text-center text-[#6d776f]">
          <strong>No matches</strong>
          <span>Try a different search.</span>
        </div>
      {/each}
    </div>
  </section>

  <section
    class="grid min-h-[55dvh] min-w-0 grid-rows-[auto_auto_1fr] bg-[linear-gradient(rgba(255,250,240,0.88),rgba(255,250,240,0.88)),repeating-linear-gradient(0deg,transparent_0_35px,rgba(37,49,46,0.08)_36px)] p-4 pb-6 md:min-h-0 md:p-6"
    aria-label="Editor"
  >
    {#if activeNote}
      <div class="mb-5 flex items-center justify-between gap-4 md:mb-6">
        <input
          class="h-11 w-[min(14rem,54vw)] rounded-lg border border-[#25312e2e] bg-[#fffaf0d1] px-3 text-sm font-extrabold text-[#37675c] md:h-10"
          aria-label="Note tag"
          value={activeNote.tag}
          oninput={(event) => updateActiveNote('tag', event.currentTarget.value)}
        />
        <div class="flex gap-2">
          <button
            class={[
              'grid size-11 shrink-0 cursor-pointer place-items-center rounded-lg border transition hover:-translate-y-0.5 hover:border-[#25312e57] md:size-10',
              activeNote.pinned
                ? 'border-[#37675c] bg-[#37675c] text-[#fffaf0]'
                : 'border-[#25312e2e] bg-[#fffaf0]'
            ]}
            aria-label={activeNote.pinned ? 'Unpin note' : 'Pin note'}
            title={activeNote.pinned ? 'Unpin note' : 'Pin note'}
            onclick={togglePinned}
          >
            <svg class="size-5 fill-none stroke-current stroke-2" viewBox="0 0 24 24" aria-hidden="true">
              <path d="m15 4 5 5-4 4v5l-1 1-4-4-5 5-2-2 5-5-4-4 1-1h5z" />
            </svg>
          </button>
          <button
            class="grid size-11 shrink-0 cursor-pointer place-items-center rounded-lg border border-[#25312e2e] bg-[#fffaf0] transition hover:-translate-y-0.5 hover:border-[#a34f45] hover:text-[#8f352b] md:size-10"
            aria-label="Delete note"
            title="Delete note"
            onclick={deleteActiveNote}
          >
            <svg class="size-5 fill-none stroke-current stroke-2" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3" />
            </svg>
          </button>
        </div>
      </div>

      <input
        class="mb-4 w-full min-w-0 border-0 bg-transparent text-[clamp(2rem,12vw,5.4rem)] leading-none font-black tracking-normal text-[#25312e] outline-none md:mb-5 md:text-[clamp(2.1rem,8vw,5.4rem)]"
        aria-label="Note title"
        value={activeNote.title}
        oninput={(event) => updateActiveNote('title', event.currentTarget.value)}
      />

      <textarea
        class="min-h-72 w-full min-w-0 resize-none border-0 bg-transparent text-base leading-7 text-[#39433f] outline-none md:min-h-0 md:text-lg"
        aria-label="Note body"
        value={activeNote.body}
        oninput={(event) => updateActiveNote('body', event.currentTarget.value)}
        placeholder="Start writing..."
      ></textarea>
    {:else}
      <div class="grid min-h-[60vh] place-items-center content-center gap-2 text-center text-[#6d776f]">
        <h2 class="m-0 text-xl font-extrabold text-[#25312e]">No note selected</h2>
        <button
          class="min-h-11 cursor-pointer rounded-lg border border-[#37675c] bg-[#37675c] px-4 text-[#fffaf0]"
          type="button"
          onclick={createNote}>Create note</button
        >
      </div>
    {/if}
  </section>
</main>
