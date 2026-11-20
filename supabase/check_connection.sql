-- Run in the Supabase SQL editor after the migration. Every row should say ok.
select 'orders table'        as check, case when to_regclass('public.orders') is not null then 'ok' else 'MISSING' end as result
union all
select 'order_events table',          case when to_regclass('public.order_events') is not null then 'ok' else 'MISSING' end
union all
select 'reply_templates table',       case when to_regclass('public.reply_templates') is not null then 'ok' else 'MISSING' end
union all
select 'RLS on orders',               case when (select relrowsecurity from pg_class where oid = 'public.orders'::regclass) then 'ok' else 'OFF' end
union all
select 'app can use orders',          case when has_table_privilege('authenticated', 'public.orders', 'select, insert, update') then 'ok' else 'NO GRANT' end
union all
select 'visitors blocked',            case when not has_table_privilege('anon', 'public.orders', 'select') then 'ok' else 'OPEN' end
union all
select 'orders in realtime',         case when exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = 'orders') then 'ok' else 'MISSING' end;
