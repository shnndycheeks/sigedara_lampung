-- ============================================================================
-- SCRIPT PERBAIKAN RLS POLICY PADA TABEL PEMINJAMAN
-- SIMASTER BIRO UMUM PROVINSI LAMPUNG
-- ============================================================================
-- Jalankan seluruh script ini di Supabase SQL Editor (Dashboard Supabase -> SQL Editor)
-- ============================================================================

-- 1. HAPUS SEMUA RLS POLICY LAMA PADA TABEL PEMINJAMAN
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'peminjaman'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON peminjaman;', pol.policyname);
    END LOOP;
END $$;

-- 2. AKTIFKAN RLS PADA TABEL PEMINJAMAN
ALTER TABLE peminjaman ENABLE ROW LEVEL SECURITY;

-- 3. BUAT RLS POLICY BARU YANG BERSIH & TRANSPARAN UNTUK PENGGUNA TERAUTENTIKASI
-- A. Policy SELECT: Semua pengguna terautentikasi dapat melihat data peminjaman
CREATE POLICY "peminjaman_select_authenticated"
ON peminjaman FOR SELECT
TO authenticated
USING (true);

-- B. Policy INSERT: Pengguna terautentikasi dapat membuat peminjaman baru
CREATE POLICY "peminjaman_insert_authenticated"
ON peminjaman FOR INSERT
TO authenticated
WITH CHECK (true);

-- C. Policy UPDATE: Pengguna terautentikasi dapat mengupdate peminjaman (termasuk persetujuan)
CREATE POLICY "peminjaman_update_authenticated"
ON peminjaman FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- D. Policy DELETE: Pengguna terautentikasi dapat menghapus peminjaman
CREATE POLICY "peminjaman_delete_authenticated"
ON peminjaman FOR DELETE
TO authenticated
USING (true);

-- ============================================================================
-- SELESAI. SILAKAN SALIN DAN TEKAN TOMBOL 'RUN' DI SQL EDITOR SUPABASE DASHBOARD.
