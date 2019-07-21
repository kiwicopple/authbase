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
- [ ] More robust session handling (expires etc)
- [ ] Reset password functionality

**Possible**

- RLS for tenants
- Possibly mplement either RBAC or ACL (cannot be extension since it isn't on RDS). Likely to be RBAC so that it is simpler to set up with DB roles. Create: OwnerRole, AdminRole, ManagerRole, MemberRole. This may be better if I can just create a Member Role and users become member of Orgs, so they can only see those orgs. From there, give the user ACL for finegrained control.