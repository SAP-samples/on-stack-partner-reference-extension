  METHOD process_category_upgrades.

    Data(current_date) = cl_abap_context_info=>get_system_date( ).
    " Get active memberships
    SELECT membershipid, business_partner
      FROM zlh_membership
      WHERE membership_status = @zif_lh_constants=>membership_status-active
      and membership_enddate > @current_date
      INTO TABLE @DATA(active_memberships).

    CHECK active_memberships IS NOT INITIAL.
    " Calculate total points
    SELECT transactions~businesspartner,
           transactions~membershipid,
           SUM( loyaltypoints ) AS total_points
      FROM zlh_r_transactions as transactions INNER JOIN @active_memberships AS active
       ON  transactions~membershipid   = active~membershipid
    AND transactions~businesspartner = active~business_partner
      GROUP BY transactions~businesspartner, transactions~membershipid
      INTO TABLE @DATA(total_points).

    CHECK total_points IS NOT INITIAL.

    " Get current active categories
    SELECT *
      FROM zlh_r_category
      FOR ALL ENTRIES IN @total_points
      WHERE businesspartner = @total_points-businesspartner
        AND status          = @zif_lh_constants=>category_status-active
        AND enddate         = @zif_lh_constants=>category_enddate          "#EC CI_NO_TRANSFORM
      INTO TABLE @DATA(categories).                                       "#EC CI_ALL_FIELDS_NEEDED



    " Get enabled category headers (sorted by threshold)
    SELECT *
      FROM zlh_i_categoryidvh
      WHERE isenabled = @abap_true
      ORDER BY Threshold ASCENDING
      INTO TABLE @DATA(category_headers).

    CHECK category_headers IS NOT INITIAL.
    SELECT businesspartner, defaultEmailAddress
      FROM I_WorkplaceAddress
      FOR ALL ENTRIES IN @total_points
      WHERE BusinessPartner = @total_points-BusinessPartner
      INTO TABLE @DATA(emails).                                                       "#EC CI_NO_TRANSFORM


    " Create hashed table for fast lookup
    DATA category_map TYPE HASHED TABLE OF zlh_i_categoryidvh
      WITH UNIQUE KEY categoryid.
    category_map = category_headers.

    " Determine upgrades
    LOOP AT total_points INTO DATA(points).

      " Check if membership is active
      CHECK line_exists( active_memberships[ membershipid = points-membershipid ] ).

      " Get current category
      DATA(current_category) = VALUE #(
        categories[
          businesspartner = points-businesspartner
          membershipid    = points-membershipid
          status          = zif_lh_constants=>category_status-active
        ] OPTIONAL
      ).
      CHECK current_category-categoryid IS NOT INITIAL.

      " Get current category details
      DATA(current_header) = VALUE #(
        category_map[ categoryid = current_category-categoryid ] OPTIONAL
      ).
      CHECK current_header-categoryid IS NOT INITIAL.

      " Check if points exceed current threshold
      CHECK points-total_points > current_header-threshold.

      " Find next eligible category
      DATA(next_category) = VALUE zlh_i_categoryidvh( ).
      LOOP AT category_headers INTO DATA(header)
        WHERE threshold > current_header-threshold
          AND threshold <= points-total_points.
        next_category = header.
      ENDLOOP.

      CHECK next_category-categoryid IS NOT INITIAL.
      CHECK next_category-categoryid <> current_category-categoryid.

      " Get email address
      DATA(email) = VALUE #( emails[ businesspartner = points-businesspartner ] OPTIONAL ).

      " Add to upgrade list
      APPEND VALUE #(
        business_partner = points-businesspartner
        membership_id    = points-membershipid
        old_category     = current_header-Categoryname
        new_category_id  = next_category-categoryid
        new_category     = next_category-Categoryname
        total_points     = points-total_points
        email_address    = email-DefaultEmailAddress
      ) TO upgrades.

    ENDLOOP.

  ENDMETHOD.