  METHOD if_sadl_exit_calc_element_read~calculate.

    DATA business_partners TYPE STANDARD TABLE OF zlh_c_businesspartner WITH DEFAULT KEY.

    business_partners = CORRESPONDING #( it_original_data ).

    IF business_partners IS INITIAL.
      RETURN.
    ENDIF.

    " Prepare business partner keys for batch loyalty points retrieval
    DATA(bp_keys) = VALUE zcl_lh_loyalty_points=>business_partner_keys(
      FOR business_partner IN business_partners
      ( sold_to_party = business_partner-SoldToParty )
    ).

    " Get loyalty points for all business partners in one call
    DATA(loyalty_results) = zcl_lh_loyalty_points=>get_points( bp_keys ).

    " Get active categories for all business partners
    SELECT FROM zlh_c_category
        FIELDS
          MembershipID,
          CategoryID,
          Status,
          Name,
          EndDate
        FOR ALL ENTRIES IN @business_partners
        WHERE MembershipID = @business_partners-MemberShipID
*          AND EndDate      = @max_date
        INTO TABLE @DATA(active_categories).

    SELECT FROM zlh_r_membership
        FIELDS
          businesspartner,
          membershipid,
          membershipstatus,
          membershipenddate
        FOR ALL ENTRIES IN @business_partners
        WHERE businesspartner = @business_partners-SoldToParty
        INTO TABLE @DATA(membership_data).

    SORT active_categories BY EndDate DESCENDING CategoryID DESCENDING.
    LOOP AT business_partners REFERENCE INTO DATA(bp).

      DATA(loyalty) = VALUE #( loyalty_results[ business_partner = bp->soldtoparty ] OPTIONAL ).
      bp->TotalLoyaltyPointsAvailable = loyalty-available.
      bp->TotalLoyaltyPointsRedeemed  = loyalty-redeemed.
      DATA(membership) = VALUE #( membership_data[ businesspartner = bp->soldtoparty ] OPTIONAL ).
      if membership-MembershipEndDate is not initial and membership-MembershipEndDate <=  cl_abap_context_info=>get_system_date( ).
        bp->LoyaltyMembershipCriticality = 1.
        bp->LltyPtsAvailableCriticality = 1.
      elseif membership-MembershipEndDate is not initial.
      bp->LoyaltyMembershipCriticality = 3.
      bp->LltyPtsAvailableCriticality = 3.
      ENDIF.

        DATA(category) = VALUE #( active_categories[ MembershipID = bp->MemberShipID ] OPTIONAL ).
      bp->MembershipCategory = category-Name.

    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( business_partners ).

  ENDMETHOD.