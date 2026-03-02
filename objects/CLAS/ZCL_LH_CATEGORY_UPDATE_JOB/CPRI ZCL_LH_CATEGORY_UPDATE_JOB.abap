  PRIVATE SECTION.
    DATA mo_log TYPE REF TO if_bali_log.
    TYPES:
      BEGIN OF upgraded_bp,
        business_partner TYPE zlh_businesspartner,
        membership_id    TYPE zlh_membership_id,
        old_category     TYPE zlh_category_name,
        new_category_id  TYPE zlh_category_id,
        new_category     TYPE zlh_category_name,
        total_points     TYPE zlh_loyaltypoint,
        email_address    TYPE zlh_email_address,
      END OF upgraded_bp,
      Upgraded_bps TYPE STANDARD TABLE OF upgraded_bp WITH EMPTY KEY.
    METHODS:
      init_log,
      add_log_msg IMPORTING iv_text TYPE string iv_ty TYPE if_bali_constants=>ty_severity DEFAULT 'I',
      process_category_upgrades
        RETURNING VALUE(upgrades) TYPE  Upgraded_bps,

      create_new_categories
        IMPORTING upgrades TYPE Upgraded_bps,

      send_notifications
        IMPORTING upgrades TYPE Upgraded_bps.