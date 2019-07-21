
-- Create schmas
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS secure;

-- pgcrypto extension

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- the names "anon" and "authenticator" are configurable and not
-- sacred, we simply choose them for clarity
create role anon;
create role authenticator noinherit; -- role to “become” other users to service authenticated HTTP requests
grant anon to authenticator;

grant usage on schema public, secure to anon;



