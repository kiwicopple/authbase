

-- login should be on your exposed schema

CREATE OR REPLACE FUNCTION public.login (email text, pass text)
  RETURNS basic_auth.jwt_token
  AS $$
DECLARE
  _role name;
  result basic_auth.jwt_token;
BEGIN
  -- check email and password
  SELECT
    basic_auth.user_role (email,
      pass) INTO _role;
  IF _role IS NULL THEN
    raise invalid_password
    USING message = 'invalid user or password';
  END IF;
  SELECT
    basic_auth.sign(row_to_json(r), 'reallyreallyreallyreallyverysafe') AS token
  FROM (
    SELECT
      _role AS ROLE,
      login.email AS email,
      extract(epoch FROM now())::integer + 60 * 60 AS exp) r INTO result;
    RETURN result;
END;
$$
LANGUAGE plpgsql
SET search_path = public, secure;

grant execute on function public.login(text,text) to anon;