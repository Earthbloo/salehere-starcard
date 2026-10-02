-- ตัวอย่าง SQL สำหรับทีม ops (repo นี้ไม่ใช้ Sequelize migration)
-- schema จริงใช้ตาม dbConfig.schema ของ user-service

CREATE TABLE star_cards (
  id                   SERIAL PRIMARY KEY,
  user_id              INTEGER      NOT NULL,
  short_id             VARCHAR(8)   NOT NULL UNIQUE,
  format               VARCHAR(16)  NOT NULL CHECK (format IN ('portfolio', 'story')),
  name                 VARCHAR(60)  NOT NULL DEFAULT '',
  is_primary           BOOLEAN      NOT NULL DEFAULT false,
  template_id          VARCHAR(40),
  schema_version       SMALLINT     NOT NULL DEFAULT 1,
  draft_doc            JSONB        NOT NULL,
  draft_rev            INTEGER      NOT NULL DEFAULT 1,
  published_version_id INTEGER,
  created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
  deleted_at           TIMESTAMPTZ
);
CREATE INDEX star_cards_user_id_idx ON star_cards (user_id) WHERE deleted_at IS NULL;
-- การ์ดหลักได้ใบเดียวต่อคน
CREATE UNIQUE INDEX star_cards_one_primary_idx ON star_cards (user_id)
  WHERE is_primary AND deleted_at IS NULL;

CREATE TABLE star_card_versions (
  id             SERIAL PRIMARY KEY,
  card_id        INTEGER      NOT NULL REFERENCES star_cards (id),
  version        INTEGER      NOT NULL,
  schema_version SMALLINT     NOT NULL,
  doc            JSONB        NOT NULL,
  page_image_ids JSONB        NOT NULL,
  og_image_id    INTEGER,
  kinds          VARCHAR(40)[] NOT NULL,
  platform       VARCHAR(16),
  app_version    VARCHAR(16),
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  UNIQUE (card_id, version)
);

CREATE TABLE star_card_images (
  card_id    INTEGER     NOT NULL REFERENCES star_cards (id),
  image_id   INTEGER     NOT NULL,
  role       VARCHAR(16) NOT NULL CHECK (role IN ('slot', 'lift', 'background', 'page')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (card_id, image_id)
);
