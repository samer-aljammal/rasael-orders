-- Where an order came from, and how it was paid.
--
-- Since the Instagram bio moved to the DM-first /link/ page, most orders
-- start as a WhatsApp or Instagram chat rather than the long form. Recording
-- the channel lets the dashboard answer "is the bio page bringing orders?".
-- Both columns are nullable: orders imported from before the app have no
-- reliable record of either.

alter table public.orders
  add column source text
    check (source in ('whatsapp', 'instagram', 'form', 'other')),
  add column payment_method text
    check (payment_method in ('sham_cash', 'syriatel_cash', 'transfer', 'cash', 'other'));

comment on column public.orders.source is
  'Channel the order arrived through: whatsapp, instagram, form or other.';
comment on column public.orders.payment_method is
  'How the customer paid, set when the order is marked paid.';
