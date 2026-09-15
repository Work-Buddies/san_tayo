-- Add the 'unverified' auth level used by OTP-gated registration.
-- Accounts sit at this level until they submit a valid OTP, then move to 'user'.
-- Run in phpMyAdmin AFTER san_tayo_schema.sql.

USE san_tayo;

INSERT INTO auth_level (level)
SELECT 'unverified'
WHERE NOT EXISTS (SELECT 1 FROM auth_level WHERE level = 'unverified');
