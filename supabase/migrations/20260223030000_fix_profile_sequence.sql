-- Fix user_profile serial sequence (was stuck at 1 due to explicit INSERT)
SELECT setval(pg_get_serial_sequence('user_profile', 'id'), COALESCE(MAX(id), 1)) FROM user_profile;
