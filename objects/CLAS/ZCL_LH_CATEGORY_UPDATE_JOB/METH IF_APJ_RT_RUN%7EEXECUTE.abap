  METHOD if_apj_rt_run~execute.

    init_log( ).
    add_log_msg( 'Job started: Loyalty Category Upgrade Process' ).

    " Process and determine upgrades
    DATA(upgrades) = process_category_upgrades( ).

    IF upgrades IS INITIAL.
      add_log_msg( 'No eligible upgrades found.' ).
      RETURN.
    ENDIF.

    add_log_msg( |Found { lines( upgrades ) } eligible memberships for upgrade.| ).

    " Create new categories
    create_new_categories( upgrades ).

    " Send email notifications
    send_notifications( upgrades ).

    add_log_msg( 'Job completed successfully.' ).

  ENDMETHOD.