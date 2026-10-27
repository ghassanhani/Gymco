-- Voice notes written down by the transcribe function count as AI usage.
alter table public.ai_usage_daily drop constraint if exists ai_usage_daily_feature_check;
alter table public.ai_usage_daily
  add constraint ai_usage_daily_feature_check check (feature in ('photo', 'write', 'eating_out', 'routine', 'coach', 'voice'));
