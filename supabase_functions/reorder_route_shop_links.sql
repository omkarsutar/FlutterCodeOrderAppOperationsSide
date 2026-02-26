-- PostgreSQL function to reorder route shop links
-- This function takes the link_id of the item being moved and its new position
-- and updates all affected items in a single transaction

CREATE OR REPLACE FUNCTION reorder_route_shop_links(
  p_link_id UUID,
  p_new_position INTEGER
)
RETURNS TABLE (
  link_id UUID,
  route_id UUID,
  shop_id UUID,
  visit_order INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_position INTEGER;
  v_route_id UUID;
BEGIN
  -- Get the current position and route_id of the item being moved
  SELECT rsl.visit_order, rsl.route_id 
  INTO v_old_position, v_route_id
  FROM route_shop_links rsl
  WHERE rsl.link_id = p_link_id;

  -- If moving down (increasing position)
  IF p_new_position > v_old_position THEN
    -- Shift items between old and new position up by 1
    UPDATE route_shop_links rsl
    SET visit_order = rsl.visit_order - 1
    WHERE rsl.route_id = v_route_id
      AND rsl.visit_order > v_old_position
      AND rsl.visit_order <= p_new_position;
  
  -- If moving up (decreasing position)
  ELSIF p_new_position < v_old_position THEN
    -- Shift items between new and old position down by 1
    UPDATE route_shop_links rsl
    SET visit_order = rsl.visit_order + 1
    WHERE rsl.route_id = v_route_id
      AND rsl.visit_order >= p_new_position
      AND rsl.visit_order < v_old_position;
  END IF;

  -- Update the moved item to its new position
  UPDATE route_shop_links rsl
  SET visit_order = p_new_position
  WHERE rsl.link_id = p_link_id;

  -- Return all items for this route in the new order
  RETURN QUERY
  SELECT 
    rsl.link_id,
    rsl.route_id,
    rsl.shop_id,
    rsl.visit_order,
    rsl.created_at,
    rsl.updated_at
  FROM route_shop_links rsl
  WHERE rsl.route_id = v_route_id
  ORDER BY rsl.visit_order ASC;
END;
$$;
