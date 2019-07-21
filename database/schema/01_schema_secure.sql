-- We put things inside the secure schema to hide
-- them from public view. Certain public procs/views will
-- refer to helpers and tables inside.

-- SET search_path = secure, public;
-- JWT Extension
-- We will create this manually so that it can be used in AWS

CREATE OR REPLACE FUNCTION secure.url_encode (data bytea)
  RETURNS text
  LANGUAGE sql
  AS $$
  SELECT
    translate(encode(data, 'base64'), E'+/=\n', '-_');
$$;

CREATE OR REPLACE FUNCTION secure.url_decode (data text)
  RETURNS bytea
  LANGUAGE sql
  AS $$
  WITH t AS (
    SELECT
      translate(data, '-_', '+/') AS trans
),
rem AS (
  SELECT
    length(t.trans) % 4 AS REMAINDER
  FROM
    t
) -- compute padding size
SELECT
  decode(t.trans || CASE WHEN rem.remainder > 0 THEN
      repeat('=', (4 - rem.remainder))
    ELSE
      ''
    END, 'base64')
FROM
  t,
  rem;
$$;

CREATE OR REPLACE FUNCTION secure.algorithm_sign (signables text, secret text, algorithm text)
  RETURNS text
  LANGUAGE sql
  AS $$
  WITH alg AS (
    SELECT
      CASE WHEN algorithm = 'HS256' THEN
        'sha256'
      WHEN algorithm = 'HS384' THEN
        'sha384'
      WHEN algorithm = 'HS512' THEN
        'sha512'
      ELSE
        ''
      END AS id
) -- hmac throws error
SELECT
  secure.url_encode (hmac(signables, secret, alg.id))
FROM
  alg;
$$;

CREATE OR REPLACE FUNCTION secure.sign(payload json, secret text, algorithm text DEFAULT 'HS256')
  RETURNS text
  LANGUAGE sql
  AS $$
  WITH header AS (
    SELECT
      secure.url_encode (convert_to('{"alg":"' || algorithm || '","typ":"JWT"}', 'utf8')) AS data
),
payload AS (
  SELECT
    secure.url_encode (convert_to(payload::text, 'utf8')) AS data
),
signables AS (
  SELECT
    header.data || '.' || payload.data AS data
  FROM
    header,
    payload
)
SELECT
  signables.data || '.' || secure.algorithm_sign (signables.data,
    secret,
    algorithm)
FROM
  signables;
$$;

CREATE OR REPLACE FUNCTION secure.verify (token text, secret text, algorithm text DEFAULT 'HS256')
  RETURNS TABLE (
    header json, payload json, valid boolean)
  LANGUAGE sql
  AS $$
  SELECT
    convert_from(secure.url_decode (r[1]), 'utf8')::json AS header,
    convert_from(secure.url_decode (r[2]), 'utf8')::json AS payload,
    r[3] = secure.algorithm_sign (r[1] || '.' || r[2],
      secret,
      algorithm) AS valid
  FROM
    regexp_split_to_array(token, '\.') r;
$$;

-- Create users table

CREATE TABLE IF NOT EXISTS secure.users (
    email text PRIMARY KEY CHECK (email ~* '^.+@.+\..+$'),
    pass text NOT NULL CHECK (length(pass) < 512),
    ROLE name NOT NULL CHECK (length(ROLE) < 512)
);

grant select on table pg_authid, secure.users to anon;

-- We would like the role to be a foreign key to actual database roles,
-- however PostgreSQL does not support these constraints against the pg_roles table.
-- We’ll use a trigger to manually enforce it.

CREATE OR REPLACE FUNCTION secure.check_role_exists ()
  RETURNS TRIGGER
  AS $$
BEGIN
  IF NOT EXISTS (
      SELECT
        1
      FROM
        pg_roles AS r
      WHERE
        r.rolname = new.role) THEN
      raise foreign_key_violation
      USING message = 'unknown database role: ' || new.role;
    RETURN NULL;
  END IF;
  RETURN new;
END
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_user_role_exists ON secure.users;

CREATE CONSTRAINT TRIGGER ensure_user_role_exists AFTER INSERT
OR UPDATE ON secure.users FOR EACH ROW EXECUTE PROCEDURE secure.check_role_exists ();

-- Next we’ll use the pgcrypto extension and a trigger to keep passwords safe
-- in the users table

CREATE OR REPLACE FUNCTION secure.encrypt_pass ()
  RETURNS TRIGGER
  AS $$
BEGIN
  IF tg_op = 'INSERT' OR new.pass <> old.pass THEN
    new.pass = crypt(new.pass, gen_salt('bf'));
  END IF;
RETURN new;
END
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS encrypt_pass ON secure.users;

CREATE TRIGGER encrypt_pass
  BEFORE INSERT
  OR UPDATE ON secure.users
  FOR EACH ROW
  EXECUTE PROCEDURE secure.encrypt_pass ();

-- With the table in place we can make a helper to check a password against
-- the encrypted column. It returns the database role for a user if the email
-- and password are correct.

CREATE OR REPLACE FUNCTION secure.user_role (email text, pass text)
  RETURNS name
  LANGUAGE plpgsql
  AS $$
BEGIN
  RETURN (
    SELECT
      ROLE
    FROM
      secure.users
    WHERE
      users.email = user_role.email
      AND users.pass = crypt(user_role.pass, users.pass));
END;
$$;

-- JWT

CREATE TYPE secure.jwt_token AS (
  token text
);
    CREATE FUNCTION secure.jwt_test ( )
      RETURNS secure.jwt_token
      AS $$
  SELECT
    secure.sign(row_to_json(r), 'reallyreallyreallyreallyverysafe') AS token
  FROM (
    SELECT
      'my_role'::text AS ROLE,
      extract(epoch FROM now())::integer + 300 AS exp) r;
$$
LANGUAGE sql;


