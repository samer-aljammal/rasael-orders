-- Run in the Supabase SQL editor after the migration. Every row should say ok.
select 'orders table'        as check, case when to_regclass('public.orders') is not null then 'ok' else 'MISSING' end as result
union all
select 'order_events table',          case when to_regclass('public.order_events') is not null then 'ok' else 'MISSING' end
union all
select 'reply_templates table',       case when to_regclass('public.reply_templates') is not null then 'ok' else 'MISSING' end
union all
select 'RLS on orders',               case when (select relrowsecurity from pg_class where oid = 'public.orders'::regclass) then 'ok' else 'OFF' end
union all
select 'orders in realtime',          case when exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'orders') then 'ok' else 'MISSING' end;
