
import axios from 'axios'

const HOST = "http://localhost:3000";
const email = `${Math.random()}@email.com`

test("Register new users", async () => {
  const url = "rpc/register";
  const payload = { email, pass: "TestPassword" };
  const { data } = await axios.post(`${HOST}/${url}`, payload);
  expect(data).toBeGreaterThan(0);
});

test("Login", async () => {
  const url = "rpc/login";
  const payload = { email, pass: "TestPassword" };
  const result = { email, role: "anon" };
  const { data } = await axios.post(`${HOST}/${url}`, payload);
  expect(data).toEqual(result);
});

test("Reset", async () => {
  const url = "rpc/update_password";
  const payload = { email, old_pass: "TestPassword", new_pass: "TestPassword1" };
  const { data } = await axios.post(`${HOST}/${url}`, payload);
  expect(data.message).toEqual('Password changed');
});

test("Login", async () => {
  const url = "rpc/login";
  const payload = { email, pass: "TestPassword1" };
  const result = { email, role: "anon" };
  const { data } = await axios.post(`${HOST}/${url}`, payload);
  expect(data).toEqual(result);
});