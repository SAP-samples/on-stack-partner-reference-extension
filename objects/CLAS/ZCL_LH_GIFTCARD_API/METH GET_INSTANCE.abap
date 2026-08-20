  METHOD get_instance.
  IF go_instance IS NOT BOUND.
    go_instance = NEW zcl_lh_giftcard_api( ).
  ENDIF.
  ro_instance = go_instance.
ENDMETHOD.