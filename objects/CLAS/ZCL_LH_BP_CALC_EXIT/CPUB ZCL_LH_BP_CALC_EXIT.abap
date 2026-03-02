CLASS zcl_lh_bp_calc_exit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_calc_element_read .
    CONSTANTS max_date TYPE zlh_end_date VALUE '99991231'.