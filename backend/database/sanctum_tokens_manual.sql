-- Fix Sanctum tokens table for MariaDB / UUID accounts.
-- Run in phpMyAdmin AFTER san_tayo_schema.sql.

USE san_tayo;

DROP TABLE IF EXISTS personal_access_tokens;

CREATE TABLE personal_access_tokens (
    id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tokenable_type  VARCHAR(100)    NOT NULL,
    tokenable_id    CHAR(36)        NOT NULL,
    name            TEXT            NOT NULL,
    token           VARCHAR(64)     NOT NULL,
    abilities       TEXT            NULL,
    last_used_at    TIMESTAMP       NULL,
    expires_at      TIMESTAMP       NULL,
    created_at      TIMESTAMP       NULL,
    updated_at      TIMESTAMP       NULL,
    UNIQUE KEY personal_access_tokens_token_unique (token),
    KEY personal_access_tokens_tokenable_type_tokenable_id_index (tokenable_type, tokenable_id),
    KEY personal_access_tokens_expires_at_index (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO migrations (migration, batch)
VALUES ('2026_08_29_055122_create_personal_access_tokens_table', 1);
