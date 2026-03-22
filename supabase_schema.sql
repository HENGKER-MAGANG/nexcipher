-- ============================================================
-- NEXCIPHER - SUPABASE SCHEMA
-- Jalankan file ini di Supabase SQL Editor
-- Dashboard -> SQL Editor -> New Query -> paste -> Run
-- ============================================================

-- ── EXTENSIONS ───────────────────────────────────────────────
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ── PROFILES (data user) ─────────────────────────────────────
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Pengguna',
  user_code   text unique not null,
  status      text default 'Tersedia',
  avatar_color text default '#5b8af0',
  last_seen   timestamptz default now(),
  created_at  timestamptz default now()
);

-- ── INVITE CODES ─────────────────────────────────────────────
create table if not exists public.invite_codes (
  id          uuid primary key default uuid_generate_v4(),
  code        text unique not null,
  created_by  uuid references public.profiles(id) on delete cascade,
  used_by     uuid references public.profiles(id),
  used_at     timestamptz,
  expires_at  timestamptz default (now() + interval '7 days'),
  is_active   boolean default true,
  created_at  timestamptz default now()
);

-- ── CONVERSATIONS ─────────────────────────────────────────────
create table if not exists public.conversations (
  id          uuid primary key default uuid_generate_v4(),
  created_at  timestamptz default now()
);

-- ── CONVERSATION MEMBERS ──────────────────────────────────────
create table if not exists public.conversation_members (
  id              uuid primary key default uuid_generate_v4(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id         uuid references public.profiles(id) on delete cascade,
  joined_at       timestamptz default now(),
  unique(conversation_id, user_id)
);

-- ── MESSAGES ─────────────────────────────────────────────────
create table if not exists public.messages (
  id              uuid primary key default uuid_generate_v4(),
  conversation_id uuid references public.conversations(id) on delete cascade,
  sender_id       uuid references public.profiles(id) on delete cascade,
  content         text not null,
  expires_at      timestamptz default (now() + interval '24 hours'),
  is_deleted      boolean default false,
  created_at      timestamptz default now()
);

-- ── INDEXES ──────────────────────────────────────────────────
create index if not exists idx_messages_conversation on public.messages(conversation_id);
create index if not exists idx_messages_expires on public.messages(expires_at);
create index if not exists idx_members_user on public.conversation_members(user_id);
create index if not exists idx_members_conv on public.conversation_members(conversation_id);
create index if not exists idx_invite_code on public.invite_codes(code);

-- ── ENABLE RLS ───────────────────────────────────────────────
alter table public.profiles enable row level security;
alter table public.invite_codes enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

-- ── RLS POLICIES - PROFILES ──────────────────────────────────
create policy "User bisa lihat semua profil"
  on public.profiles for select
  using (auth.role() = 'authenticated');

create policy "User hanya bisa update profil sendiri"
  on public.profiles for update
  using (auth.uid() = id);

create policy "User bisa insert profil sendiri"
  on public.profiles for insert
  with check (auth.uid() = id);

-- ── RLS POLICIES - INVITE CODES ──────────────────────────────
create policy "User bisa lihat kode miliknya"
  on public.invite_codes for select
  using (auth.uid() = created_by or is_active = true);

create policy "User bisa buat kode"
  on public.invite_codes for insert
  with check (auth.uid() = created_by);

create policy "User bisa update kode miliknya"
  on public.invite_codes for update
  using (auth.uid() = created_by or used_by is null);

-- ── RLS POLICIES - CONVERSATIONS ─────────────────────────────
create policy "Member bisa lihat conversation"
  on public.conversations for select
  using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = id and user_id = auth.uid()
    )
  );

create policy "User bisa buat conversation"
  on public.conversations for insert
  with check (auth.role() = 'authenticated');

-- ── RLS POLICIES - MEMBERS ───────────────────────────────────
create policy "Member bisa lihat anggota conversation"
  on public.conversation_members for select
  using (
    exists (
      select 1 from public.conversation_members cm
      where cm.conversation_id = conversation_id and cm.user_id = auth.uid()
    )
  );

create policy "User bisa join conversation"
  on public.conversation_members for insert
  with check (auth.role() = 'authenticated');

-- ── RLS POLICIES - MESSAGES ──────────────────────────────────
create policy "Member bisa baca pesan"
  on public.messages for select
  using (
    exists (
      select 1 from public.conversation_members
      where conversation_id = messages.conversation_id and user_id = auth.uid()
    )
    and is_deleted = false
    and expires_at > now()
  );

create policy "Member bisa kirim pesan"
  on public.messages for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.conversation_members
      where conversation_id = messages.conversation_id and user_id = auth.uid()
    )
  );

create policy "Pengirim bisa hapus pesannya"
  on public.messages for update
  using (auth.uid() = sender_id);

-- ── FUNCTION: Auto create profile setelah signup ─────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
declare
  v_code text;
begin
  v_code := 'NXC-' || upper(substring(md5(random()::text), 1, 4));
  while exists (select 1 from public.profiles where user_code = v_code) loop
    v_code := 'NXC-' || upper(substring(md5(random()::text), 1, 4));
  end loop;

  insert into public.profiles (id, display_name, user_code)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', 'Pengguna'),
    v_code
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ── FUNCTION: Generate invite code ───────────────────────────
create or replace function public.generate_invite_code(p_user_id uuid)
returns text language plpgsql security definer as $$
declare
  v_code text;
begin
  v_code := 'NXC-' || upper(substring(md5(random()::text), 1, 4));
  while exists (select 1 from public.invite_codes where code = v_code and is_active = true) loop
    v_code := 'NXC-' || upper(substring(md5(random()::text), 1, 4));
  end loop;

  insert into public.invite_codes (code, created_by)
  values (v_code, p_user_id);

  return v_code;
end;
$$;

-- ── FUNCTION: Validasi & pakai invite code ───────────────────
create or replace function public.use_invite_code(p_code text, p_user_id uuid)
returns json language plpgsql security definer as $$
declare
  v_invite public.invite_codes;
begin
  select * into v_invite
  from public.invite_codes
  where code = upper(p_code)
    and is_active = true
    and expires_at > now()
    and used_by is null
  limit 1;

  if not found then
    return json_build_object('success', false, 'error', 'Kode tidak valid atau sudah digunakan');
  end if;

  if v_invite.created_by = p_user_id then
    return json_build_object('success', false, 'error', 'Tidak bisa pakai kode undangan sendiri');
  end if;

  update public.invite_codes
  set used_by = p_user_id, used_at = now(), is_active = false
  where id = v_invite.id;

  return json_build_object('success', true, 'inviter_id', v_invite.created_by);
end;
$$;

-- ── FUNCTION: Get atau buat conversation ─────────────────────
create or replace function public.get_or_create_conversation(p_user1 uuid, p_user2 uuid)
returns uuid language plpgsql security definer as $$
declare
  v_conv_id uuid;
begin
  select cm1.conversation_id into v_conv_id
  from public.conversation_members cm1
  join public.conversation_members cm2
    on cm1.conversation_id = cm2.conversation_id
  where cm1.user_id = p_user1 and cm2.user_id = p_user2
  limit 1;

  if v_conv_id is null then
    insert into public.conversations default values returning id into v_conv_id;
    insert into public.conversation_members (conversation_id, user_id) values (v_conv_id, p_user1);
    insert into public.conversation_members (conversation_id, user_id) values (v_conv_id, p_user2);
  end if;

  return v_conv_id;
end;
$$;

-- ── FUNCTION: Auto hapus pesan expired ───────────────────────
create or replace function public.delete_expired_messages()
returns void language plpgsql security definer as $$
begin
  update public.messages
  set is_deleted = true
  where expires_at < now() and is_deleted = false;
end;
$$;

-- ── REALTIME: Enable untuk messages ──────────────────────────
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.profiles;

-- ── SEED: Buat 1 initial invite code (untuk admin pertama) ───
-- Jalankan ini SETELAH akun pertama dibuat:
-- select public.generate_invite_code('<your-user-id>');

-- ============================================================
-- SELESAI. Lanjut setup di SETUP_GUIDE.md
-- ============================================================
