-- Saved replies are watched live, like orders, so an edit on the phone shows
-- on the web at once. Without this the app's stream subscription is refused.
alter publication supabase_realtime add table public.reply_templates;
