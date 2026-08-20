CLASS zcl_lh_giftcard_api DEFINITION
  PUBLIC
  CREATE PUBLIC .
  PUBLIC SECTION.
   INTERFACES zif_lh_giftcard_api.
    CLASS-METHODS get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO zif_lh_giftcard_api.

    CLASS-METHODS set_instance
      IMPORTING io_instance TYPE REF TO zif_lh_giftcard_api.
