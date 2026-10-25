-- The routine builder counts its AI calls alongside the food features.
alter table public.ai_usage_daily drop constraint if exists ai_usage_daily_feature_check;
alter table public.ai_usage_daily
  add constraint ai_usage_daily_feature_check check (feature in ('photo', 'write', 'eating_out', 'routine'));
