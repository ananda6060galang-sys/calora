# Panduan Demo Calora — Rabu, 23 September 2026

Checklist persiapan presentasi 50% progress.

---

## 🔴 WAJIB SEBELUM RABU

### 1. Apply migrasi database (BELUM DIKERJAKAN — 15 menit)

Database Supabase kamu **belum punya 7 tabel** yang didokumentasikan di
laporan (Lampiran 1) dan PRD (ERD). Kalau guru buka Supabase dan tabelnya
tidak ada, itu masalah kredibilitas.

**Cara:**
1. Buka https://supabase.com/dashboard/project/kajalubgbedxmqezvdyd
2. Klik **SQL Editor** (ikon di sidebar kiri)
3. Buka file `supabase/migrations/20260919_create_core_schema.sql`
4. Copy **seluruh isinya**, paste ke SQL Editor
5. Klik **Run**

**Verifikasi** — jalankan ini di SQL Editor, harus muncul 9 tabel:
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;
```

Yang harus muncul:
`diary_entries, exercises, food_categories, food_request, foods,`
`profiles, weight_logs, workout_session, workout_sets`

> Catatan: tabelnya sengaja dibiarkan **kosong**. Laporan kamu di bagian
> "Kelemahan" sudah jujur menyebut fitur-fitur ini belum terhubung ke
> database — jadi ini konsisten, bukan kekurangan.

---

### 2. Push ke GitHub (2 menit)

6 commit masih lokal. Kalau laptop kenapa-napa, kerjaan kamu hilang.

```bash
cd /mnt/d/calora/calora
git push origin main
```
Masukkan username + Personal Access Token GitHub kamu saat diminta.

---

### 3. Install APK ke HP (5 menit)

APK release ada di:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Cara install:**
1. Colok HP ke laptop pakai kabel USB
2. Di HP: Settings → About phone → tap "Build number" 7×  (aktifkan Developer options)
3. Settings → Developer options → nyalakan **USB debugging**
4. Jalankan:
   ```bash
   cmd.exe /c "C:\SCRCPY\adb.exe install -r build/app/outputs/flutter-apk/app-release.apk"
   ```
5. Kalau muncul prompt di HP, klik **Allow**

---

### 4. Tes semua fitur di HP SEBELUM Rabu (30 menit)

**Wajib kamu tes sendiri** — jangan baru tes pas demo.

| # | Fitur | Cara tes | Hasil yang benar |
|---|---|---|---|
| 1 | Register | Daftar pakai email baru | Masuk ke Onboarding |
| 2 | Onboarding | Isi data → selesai | Masuk Dashboard, kalori muncul |
| 3 | **AI Scanner** | Foto makanan asli | Muncul nama + kalori + makro |
| 4 | Food Search | Cari "chicken" | Muncul hasil dari USDA |
| 5 | Food Diary | Tambah makanan | Muncul di daftar hari ini |
| 6 | Insights | Buka tab Insights | Ada grafik + angka |
| 7 | Profile | Ganti foto profil | Foto tersimpan |
| 8 | Logout → Login | Keluar lalu masuk lagi | Data masih ada |

> ⚠️ **Fitur 3 (AI Scanner) paling penting** — itu yang paling "wow".
> Tes pakai foto makanan yang jelas (nasi + ayam, atau buah).

---

## 🎬 ALUR DEMO YANG DISARANKAN

Urutan ini menceritakan alur lengkap, dari nol sampai ada insight:

**1. Register** — "Pertama, user daftar pakai email."
   - Pakai email baru, jangan yang sudah ada

**2. Onboarding** — "User isi data: tanggal lahir, tinggi, berat, aktivitas, tujuan."
   - Sebut: **"Umur dihitung otomatis dari tanggal lahir"**
   - Sebut: **"BMR pakai rumus Mifflin-St Jeor"**
   - Pilih goal **naikkan berat badan** biar ada surplus kalori

**3. Dashboard** — "Ini target kalori hasil perhitungan tadi."
   - Tunjuk angka target kalori + makro (protein/carbs/fat)

**4. AI Scanner** ⭐ — "Sekarang saya foto makanan saya."
   - Foto makanan asli
   - Tunggu hasil → **tunjuk confidence score**
   - Sebut: **"Hasil AI ini estimasi, user bisa edit dulu sebelum simpan"**
   - Edit porsi → simpan

**5. Food Diary** — "Hasilnya masuk ke diary hari ini."
   - Tunjuk makanan yang baru ditambahkan

**6. Food Search** — "Kalau mau manual, bisa cari juga."
   - Cari sesuatu, tambahkan

**7. Dashboard lagi** — "Lihat, angka kalorinya sudah update."
   - **Ini momen paling penting**: tunjukkan data mengalir dari diary → dashboard

**8. Insights** — "Dan ini analisis pola konsumsi saya."
   - Tunjuk grafik tren 7 hari

**9. Profile** — "Terakhir, user bisa ganti foto profil."
   - Ganti avatar, tunjukkan tersimpan

---

## 🛡️ RENCANA DARURAT

### Kalau internet sekolah jelek / mati

**AI Scanner punya penyelamat:** toggle **"Demo Mock Mode (0 token)"**
di menu `...` (titik tiga) di halaman AI Scanner.

Mode ini mengembalikan hasil contoh **tanpa internet sama sekali**.
Tes ini **sebelum Rabu** biar kamu tahu caranya.

### Kalau Supabase down

Dashboard & Diary punya **fallback ke mock data** otomatis.
Aplikasi tetap jalan, cuma datanya nggak tersimpan ke database.

### Kalau app crash saat demo

1. **Jangan panik.** Tutup app, buka lagi.
2. Kalau masih crash, lanjut ke fitur berikutnya — jangan stuck.
3. Bilang: *"Fitur ini masih dalam pengembangan, sesuai yang tertulis di laporan bagian Kelemahan."*

---

## 📱 SCREEN MIRROR KE TV

Kamu sudah punya **scrcpy** di `C:\SCRCPY\`.

```bash
# 1. Colok HP via USB, nyalakan USB debugging
# 2. Jalankan:
cmd.exe /c "C:\SCRCPY\scrcpy.exe" --max-size=1024 --max-fps=30
```

**Tips:**
- `--max-size=1024` bikin lancar di TV (jangan full resolusi)
- Window scrcpy bisa di-fullscreen: tekan `Alt+F`, atau `F11`
- **Tes ini Senin/Selasa** — jangan baru dicoba pas mau tampil
- Kalau USB bermasalah, scrcpy juga bisa via WiFi:
  ```bash
  cmd.exe /c "C:\SCRCPY\adb.exe tcpip 5555"
  cmd.exe /c "C:\SCRCPY\adb.exe connect <IP-HP>:5555"
  cmd.exe /c "C:\SCRCPY\scrcpy.exe"
  ```

---

## ❓ ANTISIPASI PERTANYAAN GURU

**"Ini datanya dari mana?"**
> "Profil dan diary tersimpan di Supabase PostgreSQL. Pencarian makanan
> pakai USDA FoodData Central lewat Supabase Edge Function. AI Scanner
> pakai Google Gemini 3.1 Flash."

**"AI-nya beneran atau mock?"**
> "Beneran. Foto dikirim ke Supabase Edge Function, diteruskan ke Gemini
> Vision API. API key-nya disimpan di server, nggak ada di aplikasi —
> jadi aman." *(tunjukkan file `supabase/functions/scan-food/index.ts`)*

**"Kenapa ada fitur yang belum jalan?"**
> "Sesuai PRD, fitur Barcode Scanner, Food Request, dan Admin Dashboard
> masuk prioritas P2 — pengembangan lanjutan. Yang saya kerjakan sekarang
> fokus ke 6 fitur P1 dulu." *(buka tabel prioritas di PRD)*

**"Ini 50%? Kok kelihatan lebih?"**
> "Yang 50% itu fitur inti P1-nya, Pak/Bu. Yang belum: integrasi database
> penuh di beberapa layar, dan tiga fitur P2."

---

## ✅ CHECKLIST AKHIR (Selasa malam)

- [ ] Migrasi SQL sudah di-run, 9 tabel muncul di Supabase
- [ ] `git push origin main` berhasil
- [ ] APK terinstall di HP
- [ ] Semua 8 fitur di tabel tes sudah dicoba di HP
- [ ] Demo Mock Mode AI Scanner sudah dites
- [ ] scrcpy sudah dites tampil di TV
- [ ] HP terisi penuh (>80%)
- [ ] Punya hotspot sendiri sebagai cadangan internet
- [ ] File laporan sudah siap dibuka
