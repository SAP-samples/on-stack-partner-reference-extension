  METHOD normalize_loyalty_points.

    " Ensure the value fits within INT8 range
    IF points > zif_lh_constants=>max_loyalty_points.
      normalized_points = zif_lh_constants=>max_loyalty_points.
    ELSEIF points < 0.
      " Handle negative points
      normalized_points = 0.
    ELSE.
      normalized_points = points.
    ENDIF.

  ENDMETHOD.