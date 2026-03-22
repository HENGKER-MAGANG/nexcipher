# NEXCIPHER — PANDUAN SETUP LENGKAP
## Waktu: ~15 menit | Gratis 100%

---

## LANGKAH 1 — Buat Project Supabase (5 menit)

1. Buka https://supabase.com → klik "Start your project"
2. Daftar dengan GitHub atau email
3. Klik "New Project"
4. Isi:
   - Name: nexcipher
   - Database Password: buat password kuat (simpan!)
   - Region: Southeast Asia (Singapore)
5. Klik "Create new project" → tunggu ~2 menit

---

## LANGKAH 2 — Jalankan SQL Schema (2 menit)

1. Di dashboard Supabase → klik "SQL Editor" (ikon database di sidebar)
2. Klik "New Query"
3. Buka file `supabase_schema.sql` → copy semua isinya
4. Paste ke SQL Editor → klik "Run"
5. Pastikan muncul pesan hijau "Success"

---

## LANGKAH 3 — Ambil API Keys (1 menit)

1. Di dashboard Supabase → klik "Settings" (ikon gear) → "API"
2. Catat dua nilai ini:
   - **Project URL** → contoh: https://abcxyz.supabase.co
   - **anon / public key** → string panjang dimulai dengan "eyJ..."

---

## LANGKAH 4 — Pasang API Keys ke App (2 menit)

1. Buka file `index.html` dengan teks editor (Notepad, VSCode, dll)
2. Cari baris ini (sekitar baris 430):
   ```
   const SUPABASE_URL  = 'GANTI_DENGAN_SUPABASE_URL';
   const SUPABASE_ANON = 'GANTI_DENGAN_SUPABASE_ANON_KEY';
   ```
3. Ganti dengan nilai asli:
   ```
   const SUPABASE_URL  = 'https://abcxyz.supabase.co';
   const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```
4. Simpan file

---

## LANGKAH 5 — Deploy ke Vercel (3 menit)

1. Buka https://vercel.com → login
2. Klik "Add New → Project"
3. Pilih "Deploy without Git" → Upload folder nexcipher-full
4. Klik Deploy
5. Dapat URL: https://nexcipher-xxx.vercel.app

---

## LANGKAH 6 — Buat Akun Pertama (Admin)

1. Buka app di browser
2. Tap "Sudah punya akun? Masuk" → JANGAN daftar dulu
3. Kita perlu buat kode undangan pertama secara manual:
   
   Di Supabase SQL Editor, jalankan:
   ```sql
   -- Daftar dulu via app, lalu jalankan ini:
   -- Ganti EMAIL dengan email yang Anda pakai saat daftar
   SELECT public.generate_invite_code(id)
   FROM public.profiles
   WHERE id = (SELECT id FROM auth.users WHERE email = 'EMAIL_ANDA' LIMIT 1);
   ```
   
   Ini akan menghasilkan kode seperti: NXC-A1B2

4. ATAU: Daftar langsung via Supabase Auth:
   - Dashboard → Authentication → Users → "Add User"
   - Isi email & password
   - Lalu jalankan SQL di atas untuk dapat kode pertama

---

## LANGKAH 7 — Aktifkan Email Auth di Supabase

1. Dashboard → Authentication → Providers
2. Pastikan "Email" aktif
3. Di "Email" settings:
   - Matikan "Confirm email" (agar tidak perlu verifikasi email dulu)
   - Atau aktifkan jika ingin verifikasi email

---

## CARA PAKAI APLIKASI

### Sebagai Admin (akun pertama):
1. Login ke app
2. Masuk ke Pengaturan → Undang via WhatsApp
3. App akan generate kode NXC-XXXX
4. Kirim kode ke teman via WhatsApp
5. Kode hanya bisa dipakai SEKALI dan expired 7 hari

### Sebagai User baru:
1. Buka app → tap "Daftar dengan kode undangan"
2. Masukkan kode NXC-XXXX yang diterima
3. Isi nama, email, password
4. Langsung masuk ke app

### Untuk chat:
1. Tap ikon + di halaman Pesan
2. Minta kode NXC pengguna lain (terlihat di Pengaturan mereka)
3. Masukkan kode → Mulai Percakapan

---

## FITUR KEAMANAN YANG AKTIF

✅ Hanya bisa masuk dengan kode undangan (tidak bisa daftar bebas)
✅ Setiap kode undangan hanya bisa dipakai 1 orang
✅ Kode expired otomatis setelah 7 hari
✅ Pesan dihapus otomatis setelah 24 jam (dari database)
✅ Row Level Security: user hanya bisa lihat percakapan sendiri
✅ Tidak ada pesan yang bisa dibaca server (RLS policy)
✅ Real-time via Supabase (bukan polling)

---

## GENERATE APK (setelah deploy)

1. Buka https://pwabuilder.com
2. Masukkan URL Vercel Anda
3. Klik "Package for Stores" → Android
4. Download APK
5. Kirim via WhatsApp / Telegram

---

## TROUBLESHOOTING

**"Kode tidak valid"**
→ Pastikan kode ditulis dengan benar, format NXC-XXXX

**Pesan tidak muncul realtime**
→ Cek koneksi internet. Refresh halaman.

**Login gagal**
→ Cek email dan password. Pastikan Confirm Email dimatikan di Supabase.

**App tidak bisa dibuka**
→ Cek SUPABASE_URL dan SUPABASE_ANON sudah diisi benar di index.html

---

Butuh bantuan? Tanyakan ke Claude dengan screenshot error-nya.
