-- ============================================================
-- LEC 在庫管理システム v14.6
-- 共有データ永続化テーブル (lec_state) セットアップ
-- ============================================================
-- 目的:
--   案件・仮押さえ・在庫・カスタム部材を Supabase の DB に保存し、
--   「ログイン/リロードしても他の人の仮押さえが消えない・確実に見える」状態にする。
--
-- 実行方法:
--   1. https://supabase.com にログイン → 対象プロジェクトを開く
--      (プロジェクト: uslqaiymvxnrdgxynhuo)
--   2. 左メニュー「SQL Editor」→「New query」
--   3. このファイルの内容を全部コピーして貼り付け
--   4. 右下「Run」をクリック (1回だけでOK)
--   5. 「Success. No rows returned」と出れば完了
--
-- 注意:
--   - これは社内ツール用の簡易構成です(anonキーで読み書き)。
--   - 実行しなくてもアプリは動きます(従来どおりのローカル+リアルタイム通知モード)。
--     実行すると自動的に「クラウド保存モード」に切り替わります。
-- ============================================================

-- 1) 共有状態テーブル (1行に全データをJSONで保存)
create table if not exists public.lec_state (
  id          text primary key,
  doc         jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  text
);

-- 2) 行レベルセキュリティを有効化
alter table public.lec_state enable row level security;

-- 3) anon キーで読み書きを許可するポリシー (社内ツールのため全許可)
--    ※ 既に同名ポリシーがある場合は一旦削除してから作り直す
drop policy if exists "lec_state_select" on public.lec_state;
drop policy if exists "lec_state_insert" on public.lec_state;
drop policy if exists "lec_state_update" on public.lec_state;

create policy "lec_state_select" on public.lec_state
  for select using (true);
create policy "lec_state_insert" on public.lec_state
  for insert with check (true);
create policy "lec_state_update" on public.lec_state
  for update using (true) with check (true);

-- 4) リアルタイム購読を有効化 (他端末の保存を自動で受け取るため)
--    既に publication に入っている場合はエラーになるので個別に無視してよい
do $$
begin
  begin
    alter publication supabase_realtime add table public.lec_state;
  exception
    when duplicate_object then null;  -- 既に追加済みなら何もしない
    when undefined_object then null;  -- publication が無い環境ならスキップ
  end;
end $$;

-- 完了。アプリをリロードすると「✅ 最新データをクラウドから取得しました」と表示されます。
