-- Create a user
CREATE OR REPLACE FUNCTION public.register (email text, pass text)
  RETURNS int
  LANGUAGE plpgsql
  AS $$
DECLARE
  auth_user_id int;
BEGIN
  INSERT INTO secure.users (email, pass, role)
    VALUES (register.email, register.pass, 'anon')
  RETURNING
    id INTO auth_user_id;
  RETURN auth_user_id;
END;
$$ SET search_path = public, secure;

-- login should be on your exposed schema

CREATE OR REPLACE FUNCTION public.login (email text, pass text)
  RETURNS jsonb
  LANGUAGE plpgsql
  AS $$
DECLARE
  auth_user_id int;
BEGIN
  auth_user_id := secure.verify_login (email,
    pass);
  CASE WHEN auth_user_id IS NOT NULL THEN
    -- Logged
    RETURN row_to_json(t)
  FROM (
    SELECT
      users.email,
      users.role
    FROM
      secure.users
    WHERE
      id = auth_user_id) t;
ELSE
  -- Incorrect user
  raise invalid_password
  USING message = 'Invalid email or password.';
END CASE;
END;
$$ SET search_path = public, secure;

GRANT EXECUTE ON FUNCTION public.login (text, text)
TO anon;

CREATE OR REPLACE FUNCTION public.update_password (email text, old_pass text, new_pass text)
  RETURNS jsonb
  LANGUAGE plpgsql
  AS $$
DECLARE
  auth_user_id int8;
BEGIN
  auth_user_id := verify_login (email,
    old_pass);
  IF auth_user_id IS NOT NULL THEN
    -- Set password to new password
    UPDATE
      secure.users
    SET
      pass = new_pass
    WHERE
      id = auth_user_id;
    RETURN json_build_object('result', TRUE, 'user_id', auth_user_id, 'message', 'Password changed');
  ELSE
    -- Incorrect user
    raise invalid_password
    USING message = 'Invalid email or password.';
  END IF;
END;
$$ SET search_path = public, secure;

