-- ============================================================
-- Schema: san_tayo (Daet Listings App)
-- Target: MySQL 8.0+ / MariaDB
-- Notes:
--   - PK generation strategy:
--       * DB-generated (DEFAULT (UUID())): everything except listing
--         (auth_level, listing_status, barangay, food_type, account,
--         landmark, listing_img, listing_menu, listing_food_type).
--       * App-generated (PHP supplies the UUID on INSERT): listing only.
--         This is the one id PHP needs upfront, since it's the FK
--         reused when inserting into listing_img / listing_menu /
--         listing_food_type in the same request.
--   - listing.active            -> soft "deactivate" flag for the listing itself.
--                                   Listing is only hard-deleted when the owner/admin
--                                   permanently deletes it (child rows cascade at that point).
--   - listing_img/menu/food_type.deleted_at -> soft delete for child rows.
--                                   NULL = active/visible. Setting it marks as deleted;
--                                   business can "undelete" anytime by setting it back to NULL.
--                                   A scheduled EVENT permanently purges rows 30+ days
--                                   after deleted_at (see bottom of this script).
-- ============================================================

CREATE DATABASE IF NOT EXISTS san_tayo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE san_tayo;

-- ------------------------------------------------------------
-- Lookup tables (no FKs)
-- ------------------------------------------------------------

CREATE TABLE auth_level (
    id    CHAR(36)     NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    level VARCHAR(20)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE listing_status (
    id     CHAR(36)     NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    status VARCHAR(20)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE barangay (
    id   CHAR(36)      NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    name VARCHAR(255)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE food_type (
    id          CHAR(36)      NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    name        VARCHAR(255)  NOT NULL,
    description VARCHAR(255)  NOT NULL
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Core tables
-- ------------------------------------------------------------

CREATE TABLE account (
    id             CHAR(36)      NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    email          VARCHAR(255)  NOT NULL,
    password_hash  VARCHAR(255)  NOT NULL,
    username       VARCHAR(255)  NOT NULL,
    auth_level_id  CHAR(36)      NOT NULL,
    created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_account_email    UNIQUE (email),
    CONSTRAINT uq_account_username UNIQUE (username),

    CONSTRAINT fk_account_auth_level
        FOREIGN KEY (auth_level_id) REFERENCES auth_level(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE landmark (
    id            CHAR(36)        NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    barangay_id   CHAR(36)        NOT NULL,
    name          VARCHAR(255)    NOT NULL,
    map_latitude  DECIMAL(9,6)    NOT NULL,
    map_longitude DECIMAL(9,6)    NOT NULL,

    CONSTRAINT fk_landmark_barangay
        FOREIGN KEY (barangay_id) REFERENCES barangay(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE listing (
    id                  CHAR(36)      NOT NULL PRIMARY KEY,
    account_id          CHAR(36)      NOT NULL,
    landmark_id         CHAR(36)      NOT NULL,
    listing_status_id   CHAR(36)      NOT NULL,
    title               VARCHAR(255)  NOT NULL,
    description         LONGTEXT      NOT NULL,
    address_street      VARCHAR(255)  NOT NULL,
    address_purok       VARCHAR(255)  NOT NULL,
    active              BOOLEAN       NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_listing_account
        FOREIGN KEY (account_id) REFERENCES account(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_listing_landmark
        FOREIGN KEY (landmark_id) REFERENCES landmark(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_listing_status
        FOREIGN KEY (listing_status_id) REFERENCES listing_status(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Listing detail / child tables (soft-deletable)
-- ------------------------------------------------------------

CREATE TABLE listing_img (
    id         CHAR(36)      NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    listing_id CHAR(36)      NOT NULL,
    img        BLOB          NOT NULL,
    alt_text   VARCHAR(255),
    deleted_at TIMESTAMP     NULL DEFAULT NULL,

    CONSTRAINT fk_listing_img_listing
        FOREIGN KEY (listing_id) REFERENCES listing(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE listing_menu (
    id          CHAR(36)       NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    listing_id  CHAR(36)       NOT NULL,
    item        VARCHAR(255)   NOT NULL,
    price       DECIMAL(10,2)  NOT NULL,
    description LONGTEXT,
    deleted_at  TIMESTAMP      NULL DEFAULT NULL,

    CONSTRAINT fk_listing_menu_listing
        FOREIGN KEY (listing_id) REFERENCES listing(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE listing_food_type (
    id            CHAR(36)   NOT NULL DEFAULT (UUID()) PRIMARY KEY,
    listing_id    CHAR(36)   NOT NULL,
    food_type_id  CHAR(36)   NOT NULL,
    deleted_at    TIMESTAMP  NULL DEFAULT NULL,

    CONSTRAINT uq_listing_food_type UNIQUE (listing_id, food_type_id),

    CONSTRAINT fk_listing_food_type_listing
        FOREIGN KEY (listing_id) REFERENCES listing(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_listing_food_type_food_type
        FOREIGN KEY (food_type_id) REFERENCES food_type(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Seed data: listing_status / auth_level
-- ------------------------------------------------------------

INSERT INTO listing_status (status) VALUES
    ('pending'),
    ('viewed'),
    ('approved'),
    ('rejected');

INSERT INTO auth_level (level) VALUES
    ('admin'),
    ('business'),
    ('user');

-- ------------------------------------------------------------
-- Seed data: barangay (Daet, Camarines Norte — 25 barangays)
-- NOTE: This list is compiled from the best available public sources.
-- The 8 numbered Poblacion barangays and Alawihao/Awitan/Bagasbas/
-- Borabod/Bibirao are well-corroborated. Please cross-check the full
-- list against the official LGU (lgudaet.gov.ph) or PSA/PSGC records
-- before relying on it for production/legal use.
-- ------------------------------------------------------------

INSERT INTO barangay (name) VALUES
    ('Alawihao'),
    ('Awitan'),
    ('Bagasbas'),
    ('Barangay I (Poblacion)'),
    ('Barangay II (Poblacion)'),
    ('Barangay III (Poblacion)'),
    ('Barangay IV (Poblacion)'),
    ('Barangay V (Poblacion)'),
    ('Barangay VI (Poblacion)'),
    ('Barangay VII (Poblacion)'),
    ('Barangay VIII (Poblacion)'),
    ('Bibirao'),
    ('Borabod'),
    ('Calasgasan'),
    ('Camambugan'),
    ('Dogongan'),
    ('Gahonon'),
    ('Gubat'),
    ('Lag-on'),
    ('Magang'),
    ('Mancruz'),
    ('Mantugawe'),
    ('Pamorangon'),
    ('San Isidro'),
    ('Tagas');

-- ------------------------------------------------------------
-- Seed data: food_type (common cuisine/category tags for PH/Daet
-- food businesses)
-- ------------------------------------------------------------

INSERT INTO food_type (name, description) VALUES
    ('Filipino', 'Traditional Filipino home-style dishes (adobo, sinigang, kare-kare, etc.)'),
    ('Bicolano', 'Bicol regional specialties known for chili and coconut milk (Bicol express, laing, etc.)'),
    ('Seafood', 'Fresh and cooked seafood dishes such as grilled fish, shrimp, and shellfish'),
    ('Grilled / Inihaw', 'Charcoal-grilled meats, seafood, and street-style barbecue'),
    ('Street Food', 'Filipino street food and snacks (fishball, kwek-kwek, isaw, etc.)'),
    ('Silog / Breakfast', 'Filipino breakfast meals served with garlic rice and egg (tapsilog, hotsilog, etc.)'),
    ('Fast Food', 'Quick-service fast food chains and casual fried chicken/burger spots'),
    ('Pulutan / Bar Chow', 'Beer-pairing appetizers and finger food typically served at bars'),
    ('Desserts & Pastries', 'Cakes, pastries, and local sweets including pili-based treats'),
    ('Coffee & Cafe', 'Coffee shops and cafes serving brewed coffee, pastries, and light meals'),
    ('Halo-Halo & Ice Cream', 'Cold Filipino desserts such as halo-halo, sorbetes, and shaved ice treats'),
    ('Chinese', 'Chinese-Filipino cuisine (siomai, siopao, noodles, etc.)'),
    ('Pizza & Italian', 'Pizza, pasta, and other Italian-inspired dishes'),
    ('Lechon & Roasts', 'Whole roasted or lechon-style pork and chicken specialists'),
    ('Halal', 'Halal-certified or halal-friendly food establishments');

-- ============================================================
-- Scheduled purge: permanently delete soft-deleted child rows
-- (listing_img, listing_menu, listing_food_type) after 30 days.
-- Requires the MySQL event scheduler to be enabled:
--   SET GLOBAL event_scheduler = ON;
-- (Set this in your server config / init script — SET GLOBAL does
--  not persist across restarts unless added to my.cnf as
--  event_scheduler=ON.)
-- ============================================================

DELIMITER $$

CREATE EVENT IF NOT EXISTS purge_soft_deleted_listing_children
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 2 HOUR)
DO
BEGIN
    DELETE FROM listing_img
    WHERE deleted_at IS NOT NULL
      AND deleted_at < (NOW() - INTERVAL 30 DAY);

    DELETE FROM listing_menu
    WHERE deleted_at IS NOT NULL
      AND deleted_at < (NOW() - INTERVAL 30 DAY);

    DELETE FROM listing_food_type
    WHERE deleted_at IS NOT NULL
      AND deleted_at < (NOW() - INTERVAL 30 DAY);
END$$

DELIMITER ;