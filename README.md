# Authbase

An starter repo for a multitent PostgreSQL database, using PostgREST as an API. All functionality works on RDS (at least the latest version).

**Tables**

- Users
- Sessions for storing logins
- Organizations 
- Members - each user can belong to one or many organisations

**Features**

- Login / Register / Update Password
- User passwords are hashed
- User table and sessions are stored in a seperate schema for security

**Roadmap**

- [ ] Implement either RBAC or ACL (cannot be extension since it isn't on RDS)
- [ ] More robust session handling (expires etc)
- [ ] Reset password functionality

**Possible**

- RLS for tenants