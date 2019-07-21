
-- Create schmas
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS secure;

-- Extensions

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- the names "anon" and "authenticator" are configurable and not
-- sacred, we simply choose them for clarity
create role anon;
create role authenticator noinherit; -- role to “become” other users to service authenticated HTTP requests

grant anon to authenticator;
grant usage on schema public, secure to anon;



