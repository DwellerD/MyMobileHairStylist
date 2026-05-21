-- Add customer contact phone number to appointments for in-home logistics
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS customer_phone text;

COMMENT ON COLUMN appointments.customer_phone IS
  'Customer contact phone number captured at booking time for in-home appointment logistics.';
