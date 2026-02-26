-- Function to resequence visit_order after deletion
-- This ensures visit_order values are always sequential (1, 2, 3, 4...)
CREATE OR REPLACE FUNCTION resequence_visit_order_after_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Resequence all items in the same route that come after the deleted item
  UPDATE route_shop_links rsl
  SET visit_order = rsl.visit_order - 1
  WHERE rsl.route_id = OLD.route_id
    AND rsl.visit_order > OLD.visit_order;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run after delete
CREATE TRIGGER resequence_after_delete
  AFTER DELETE ON route_shop_links
  FOR EACH ROW
  EXECUTE FUNCTION resequence_visit_order_after_delete();
