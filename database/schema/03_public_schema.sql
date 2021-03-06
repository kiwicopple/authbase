
-- ----------------------------
-- Table structure for organizations
-- ----------------------------
create table "public"."organzations" (
    "id" int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    "inserted_at" timestamp without time zone not null default now(),
    "updated_at" timestamp without time zone not null default now(),
    "slug" text NOT NULL CHECK (length(slug) < 40) UNIQUE,
    "name" text NOT NULL CHECK (length(name) < 100) UNIQUE
);
comment on column organzations.slug is 'A unique identifier for the organization. Should only contain letters and hyphens';


-- ----------------------------
-- Table structure for memberships
-- ----------------------------
create table "public"."memberships" (
  "id" int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "inserted_at" timestamp without time zone not null default now(),
  "updated_at" timestamp without time zone not null default now(),
  "organization_id" int not null REFERENCES "public"."organzations",
  "user_id" int not null REFERENCES "secure"."users",
  "role" name NOT NULL CHECK (length(ROLE) < 512)
);