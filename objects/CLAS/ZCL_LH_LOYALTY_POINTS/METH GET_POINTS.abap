  METHOD get_points.

    IF business_partners IS INITIAL.
      RETURN.
    ENDIF.

    DATA(today) = cl_abap_context_info=>get_system_date( ).
    DATA actual_points TYPE HASHED TABLE OF loyalty_point WITH UNIQUE KEY business_partner.

    " Calculate loyalty points with membership status consideration in one query
    SELECT FROM zlh_r_transactions AS transactions
      INNER JOIN @business_partners AS keys
        ON transactions~businesspartner = keys~sold_to_party
      LEFT OUTER JOIN zlh_r_membership AS membership
        ON transactions~businesspartner = membership~businesspartner
      FIELDS
        transactions~businesspartner,
        " Available points calculation
        SUM( CASE
               " For INACTIVE memberships: include points ONLY if expiry date = membership end date
               WHEN membership~membershipstatus = 'I'
               THEN 0

               " For ACTIVE memberships: include points if expiry date >= today
               WHEN ( membership~membershipstatus IS INITIAL OR membership~membershipstatus = @zif_lh_constants=>membership_status-active )
                 AND transactions~activitytype IN (@zif_lh_constants=>activity-accrual, @zif_lh_constants=>activity-bonus,
                 @zif_lh_constants=>activity-promotion, @zif_lh_constants=>activity-purchase)
               THEN transactions~loyaltypoints
               ELSE 0
             END )
        - SUM( CASE
        WHEN membership~membershipstatus = 'I'
               THEN 0
                 WHEN transactions~activitytype = @zif_lh_constants=>activity-redemption
                 THEN transactions~loyaltypoints
                 WHEN transactions~activitytype = @zif_lh_constants=>activity-deactivation
                 THEN transactions~loyaltypoints
                 ELSE 0
               END ) AS available,

        " Redeemed points
        SUM( CASE
               WHEN transactions~activitytype = @zif_lh_constants=>activity-redemption
               THEN transactions~loyaltypoints

               WHEN transactions~activitytype = @zif_lh_constants=>activity-deactivation
               THEN transactions~loyaltypoints
               ELSE 0
             END ) AS redeemed
      GROUP BY transactions~businesspartner
      INTO TABLE @actual_points.

    " Populate the final results
    points = VALUE #( FOR partner IN business_partners
                       LET actual = VALUE loyalty_point( actual_points[ business_partner = partner-sold_to_party ] OPTIONAL ) IN
                       ( business_partner = partner-sold_to_party
                         available        = COND #( WHEN actual-business_partner IS NOT INITIAL
                                                    THEN normalize_loyalty_points( actual-available )
                                                    ELSE 0 )
                         redeemed         = COND #( WHEN actual-business_partner IS NOT INITIAL
                                                    THEN normalize_loyalty_points( actual-redeemed )
                                                    ELSE 0 )
                       ) ).

  ENDMETHOD.