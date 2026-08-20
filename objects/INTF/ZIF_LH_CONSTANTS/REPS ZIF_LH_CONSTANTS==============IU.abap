INTERFACE zif_lh_constants
  PUBLIC .
  CONSTANTS: BEGIN OF activity,
               purchase     TYPE zlh_activity_type VALUE 'Purchase',
               redemption   TYPE zlh_activity_type VALUE 'Redemption',
               accrual      TYPE zlh_activity_type VALUE 'Accrual',
               bonus        TYPE zlh_activity_type VALUE 'Bonus',
               accrul       TYPE zlh_activity_type VALUE 'Accrual',
               promotion    TYPE zlh_activity_type VALUE 'Promotion',
               deactivation TYPE zlh_activity_type VALUE 'Deactivation',
             END OF activity,

             BEGIN OF category_status,
               active   TYPE zlh_category_status VALUE 'A',
               inactive TYPE zlh_category_status VALUE 'I',
             END OF category_status,

             BEGIN OF membership_status,
               active   TYPE zlh_membership_status VALUE 'A',
               inactive TYPE zlh_membership_status VALUE 'I',
             END OF membership_status,

             BEGIN OF giftcard_status,
               active   TYPE zlh_giftcard_status VALUE 'A',
               inactive TYPE zlh_giftcard_status VALUE 'I',
             END OF giftcard_status,

             sales_order_completion_status TYPE I_SalesOrderTP-HdrGeneralIncompletionStatus VALUE 'C',

             category_enddate              TYPE datum VALUE '99991231',
             membership_enddate            TYPE datum VALUE '99991231',
             max_loyalty_points            TYPE zlh_loyaltypoint VALUE 9999999999999999,
             max_giftcard_value            TYPE zlh_giftcardamt VALUE '9999999999999.99',
             default_currency              TYPE zlh_currency VALUE 'EUR'.

ENDINTERFACE.