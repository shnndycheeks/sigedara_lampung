-- ============================================================================
-- SCRIPT PERBAIKAN RLS POLICY UNTUK SELURUH TABEL (PEMINJAMAN, ARSIP, DISPOSISI)
-- SIMASTER BIRO UMUM PROVINSI LAMPUNG
-- ============================================================================
-- Jalankan seluruh script ini di Supabase SQL Editor (Dashboard Supabase -> SQL Editor)
-- ============================================================================

-- ------------------------------------------------------------
-- 1. TABEL: PEMINJAMAN
-- ------------------------------------------------------------
-- Hapus semua policy lama pada tabel peminjaman
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

-- Aktifkan RLS
ALTER TABLE peminjaman ENABLE ROW LEVEL SECURITY;

-- Buat policy baru
CREATE POLICY "peminjaman_select_authenticated" ON peminjaman FOR SELECT TO authenticated USING (true);
CREATE POLICY "peminjaman_insert_authenticated" ON peminjaman FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "peminjaman_update_authenticated" ON peminjaman FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "peminjaman_delete_authenticated" ON peminjaman FOR DELETE TO authenticated USING (true);


-- ------------------------------------------------------------
-- 2. TABEL: ARSIP_SURAT
-- ------------------------------------------------------------
-- Hapus semua policy lama pada tabel arsip_surat
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

-- Aktifkan RLS
ALTER TABLE arsip_surat ENABLE ROW LEVEL SECURITY;

-- Buat policy baru (supaya semua Katim/TU bisa edit/soft-delete surat)
CREATE POLICY "arsip_surat_select_authenticated" ON arsip_surat FOR SELECT TO authenticated USING (true);
CREATE POLICY "arsip_surat_insert_authenticated" ON arsip_surat FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "arsip_surat_update_authenticated" ON arsip_surat FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "arsip_surat_delete_authenticated" ON arsip_surat FOR DELETE TO authenticated USING (true);


-- ------------------------------------------------------------
-- 3. TABEL: DISPOSISI
-- ------------------------------------------------------------
-- Hapus semua policy lama pada tabel disposisi
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

-- Aktifkan RLS
ALTER TABLE disposisi ENABLE ROW LEVEL SECURITY;

-- Buat policy baru
CREATE POLICY "disposisi_select_authenticated" ON disposisi FOR SELECT TO authenticated USING (true);
CREATE POLICY "disposisi_insert_authenticated" ON disposisi FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "disposisi_update_authenticated" ON disposisi FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "disposisi_delete_authenticated" ON disposisi FOR DELETE TO authenticated USING (true);

-- ============================================================================
-- SELESAI. SILAKAN SALIN DAN RUN DI SQL EDITOR SUPABASE DASHBOARD.
