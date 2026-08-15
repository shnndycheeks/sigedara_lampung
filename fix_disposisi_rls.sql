-- ============================================================================
-- SCRIPT PERBAIKAN RLS POLICY & SKEMA TABEL DISPOSISI
-- SIMASTER BIRO UMUM PROVINSI LAMPUNG
-- ============================================================================
-- Jalankan seluruh script ini di Supabase SQL Editor (Dashboard Supabase -> SQL Editor)
-- ============================================================================

-- 1. TAMPUNG DAN PASTIKAN SEMUA KOLOM DISPOSISI TERSEDIA
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS instruksi TEXT;
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS instruksi_disposisi TEXT;
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS catatan TEXT;
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS ttd_png TEXT;
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS parent_disposisi_id TEXT;
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS opened_at TIMESTAMPTZ;
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;
ALTER TABLE disposisi ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2. HAPUS SEMUA RLS POLICY LAMA PADA TABEL DISPOSISI YANG MENYEBABKAN REKURSI (42P17)
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'disposisi'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON disposisi;', pol.policyname);
    END LOOP;
END $$;

-- 3. AKTIFKAN RLS PADA TABEL DISPOSISI
ALTER TABLE disposisi ENABLE ROW LEVEL SECURITY;

-- 4. BUAT RLS POLICY BARU YANG BERSIH & BEBAS REKURSI (PERMITTED FOR ALL AUTHENTICATED ROLES)
-- A. Policy SELECT: Semua role (TU, Karo, Kabag, Katim, Pegawai) dapat melihat semua data disposisi
CREATE POLICY "disposisi_select_all_authenticated"
ON disposisi FOR SELECT
TO authenticated
USING (true);

-- B. Policy INSERT: Pengguna yang terautentikasi dapat membuat record disposisi baru
CREATE POLICY "disposisi_insert_authenticated"
ON disposisi FOR INSERT
TO authenticated
WITH CHECK (true);

-- C. Policy UPDATE: Pengguna yang terautentikasi dapat memperbarui status/catatan disposisi
CREATE POLICY "disposisi_update_authenticated"
ON disposisi FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- D. Policy DELETE: Pengguna yang terautentikasi dapat menghapus/menarik disposisi jika diperlukan
CREATE POLICY "disposisi_delete_authenticated"
ON disposisi FOR DELETE
TO authenticated
USING (true);


-- 5. PASTIKAN TABEL ARSIP_SURAT JUGA MEMILIKI RLS POLICY YANG LENGKAP & TRANSPARAN
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'arsip_surat'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON arsip_surat;', pol.policyname);
    END LOOP;
END $$;

ALTER TABLE arsip_surat ENABLE ROW LEVEL SECURITY;

CREATE POLICY "arsip_surat_select_authenticated"
ON arsip_surat FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "arsip_surat_insert_authenticated"
ON arsip_surat FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "arsip_surat_update_authenticated"
ON arsip_surat FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "arsip_surat_delete_authenticated"
ON arsip_surat FOR DELETE
TO authenticated
USING (true);

-- ============================================================================
-- SELESAI. SILAKAN TEKAN TOMBOL 'RUN' PADA DASHBOARD SUPABASE SQL EDITOR.
-- ============================================================================
