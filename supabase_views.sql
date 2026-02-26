-- Run this script in your Supabase SQL Editor

create view public.view_route_shop_links as
select
  l.link_id,
  l.route_id,
  l.shop_id,
  l.visit_order,
  l.created_at,
  l.updated_at,
  r.route_name as route_id_label,
  s.shop_name as shop_id_label,
  s.shops_primary_route,
  sr.route_name as shops_primary_route_label
from
  route_shop_links l
  left join routes r on l.route_id = r.route_id
  left join shops s on l.shop_id = s.shop_id
  left join routes sr on s.shops_primary_route = sr.route_id
where
  s.is_active = true
  and (
    r.is_active = true
    or r.is_active is null
  )
  and (
    sr.is_active = true
    or sr.is_active is null
  );



-- RBAC Permissions View
create view public.view_rbac_permissions as
select
  p.permission_id,
  p.role_id,
  p.module_id,
  p.can_read,
  p.can_create,
  p.can_update,
  p.can_delete,
  p.created_at,
  p.updated_at,
  r.role_name as role_id_label,
  m.module_name as module_id_label
from
  rbac_permissions p
  left join rbac_roles r on p.role_id = r.role_id
  left join rbac_modules m on p.module_id = m.module_id;



create view public.view_po_items as
select
  i.po_item_id,
  i.po_id,
  i.product_id,
  i.item_name,
  i.item_qty,
  i.item_sell_rate,
  i.item_price,
  i.item_unit_mrp,
  i.profit_to_shop,
  i.created_by,
  i.updated_by,
  i.created_at,
  i.updated_at,
  pr.product_name as product_id_label,
  pr.product_weight_value as product_weight_value_label,
  pr.product_weight_unit as product_weight_unit_label,
  pr.product_type as product_type_label,
  uc.full_name as created_by_label,
  uu.full_name as updated_by_label
from
  po_item i
  left join product pr on i.product_id = pr.product_id
  left join users uc on i.created_by = uc.user_id
  left join users uu on i.updated_by = uu.user_id;



create view public.view_products as
select
  p.product_id,
  p.product_type,
  p.product_name,
  p.product_weight_value,
  p.product_weight_unit,
  p.purchase_rate_for_retailer,
  p.mrp,
  p.packaging_type,
  p.pieces_per_outer,
  p.is_outer,
  p.is_active,
  p.is_available,
  p.qtyindecimal,
  p.product_image_url,
  p.created_by,
  p.updated_by,
  p.created_at,
  p.updated_at,
  uc.full_name as created_by_label,
  uu.full_name as updated_by_label
from
  product p
  left join users uc on p.created_by = uc.user_id
  left join users uu on p.updated_by = uu.user_id
where
  p.is_active = true;



create view public.view_purchase_orders as
select
  po.po_id,
  po.po_total_amount,
  po.po_line_item_count,
  po.po_route_id,
  po.po_shop_id,
  po.user_comment,
  po.profit_to_shop,
  po.po_lat,
  po.po_long,
  po.status,
  po.created_by,
  po.updated_by,
  po.created_at,
  po.updated_at,
  r.route_name as po_route_id_label,
  s.shop_name as po_shop_id_label,
  s.shop_address as shop_address_label,
  s.shop_note as shop_note_label,
  s.shop_mobile_1 as shop_mobile_label,
  uc.full_name as created_by_label,
  uu.full_name as updated_by_label,
  l.visit_order
from
  purchase_order po
  left join routes r on po.po_route_id = r.route_id
  left join shops s on po.po_shop_id = s.shop_id
  left join route_shop_links l on po.po_shop_id = l.shop_id
  and po.po_route_id = l.route_id
  left join users uc on po.created_by = uc.user_id
  left join users uu on po.updated_by = uu.user_id;


    
create view public.view_shops as
select
  s.shop_id,
  s.shop_name,
  s.shops_primary_route,
  s.shop_note,
  s.hidden_note,
  s.shop_mobile_1,
  s.shop_mobile_2,
  s.shop_person_name,
  s.is_active,
  s.shop_location_url,
  s.shop_landmark,
  s.shop_address,
  s.shop_photo_id,
  s.shop_photo_url,
  s.shop_lat,
  s.shop_long,
  s.created_at,
  s.updated_at,
  r.route_name as shops_primary_route_label,
  l.visit_order
from
  shops s
  left join routes r on s.shops_primary_route = r.route_id
  left join route_shop_links l on s.shop_id = l.shop_id
  and s.shops_primary_route = l.route_id
where
  s.is_active = true
  and (
    r.is_active = true
    or r.is_active is null
  );




create view public.view_users as
select
  u.user_id,
  u.full_name,
  u.role_id,
  u.preferred_route_id,
  u.created_at,
  u.updated_at,
  r.role_name as role_id_label,
  rt.route_name as preferred_route_id_label
from
  users u
  left join rbac_roles r on u.role_id = r.role_id
  left join routes rt on u.preferred_route_id = rt.route_id;
  


create view public.view_shop_dropdown as
select
  shop_id,
  shop_name
from
  shops
where
  is_active = true
order by
  shop_name;


create view public.view_po_collections as
select
  pc.collection_id,
  pc.po_id,
  pc.collected_amount,
  pc.is_cash,
  pc.is_online,
  pc.is_cheque,
  pc.cheque_no,
  pc.is_sign,
  pc.sign_amount,
  pc.comments,
  pc.created_at,
  pc.updated_at,
  pc.created_by,
  pc.updated_by,
  po.status as po_status_label,
  po.updated_at as po_updated_at,
  s.shop_name as shop_id_label,
  r.route_name as route_id_label,
  uc.full_name as created_by_label,
  uu.full_name as updated_by_label
from
  po_collections pc
  left join purchase_order po on pc.po_id = po.po_id
  left join shops s on po.po_shop_id = s.shop_id
  left join routes r on po.po_route_id = r.route_id
  left join users uc on pc.created_by = uc.user_id
  left join users uu on pc.updated_by = uu.user_id;



DROP VIEW IF EXISTS public.view_retailer_shop_link;
CREATE VIEW public.view_retailer_shop_link AS
SELECT
  rsl.link_id,
  rsl.user_id,
  rsl.shop_id,
  rsl.created_at,
  rsl.updated_at,
  rsl.created_by,
  rsl.updated_by,
  u.full_name AS user_id_label,
  rr.role_name AS user_role_label,
  s.shop_name AS shop_id_label,
  r.route_name AS shop_route_label
FROM
  retailer_shop_link rsl
  LEFT JOIN users u ON rsl.user_id = u.user_id
  LEFT JOIN rbac_roles rr ON u.role_id = rr.role_id
  LEFT JOIN shops s ON rsl.shop_id = s.shop_id
  LEFT JOIN routes r ON s.shops_primary_route = r.route_id;


