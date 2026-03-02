  METHOD create_new_categories.

    DATA new_categories TYPE TABLE FOR CREATE zlh_r_membership\_category.

    LOOP AT upgrades INTO DATA(upgrade).

      APPEND VALUE #(
        membershipid = upgrade-membership_id
        %target      = VALUE #( (
          %cid              = |CID_{ sy-tabix }|
          membershipid      = upgrade-membership_id
          categoryid        = upgrade-new_category_id
          status            = zif_lh_constants=>category_status-active
          %control-membershipid = if_abap_behv=>mk-on
          %control-categoryid   = if_abap_behv=>mk-on
          %control-status       = if_abap_behv=>mk-on
        ) )
      ) TO new_categories.

    ENDLOOP.

    CHECK new_categories IS NOT INITIAL.

    MODIFY ENTITIES OF zlh_r_businesspartner
      ENTITY zlh_r_membership
        CREATE BY \_category
        FROM new_categories
      FAILED DATA(failed)
      REPORTED DATA(reported).
    IF failed IS INITIAL.
      COMMIT WORK.
      add_log_msg( |Successfully updated { lines( new_categories ) } membership categories.| ).
    ELSE.
      add_log_msg( iv_text = 'Failed to update membership categories.' iv_ty = 'E' ).
    ENDIF.
  ENDMETHOD.