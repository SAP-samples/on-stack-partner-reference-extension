  METHOD send_notifications.
    DATA(current_date) = cl_abap_context_info=>get_system_date( ).
    LOOP AT upgrades INTO DATA(upgrade).

      " Skip if no email
      CHECK upgrade-email_address IS NOT INITIAL.

      TRY.
          " Create and send email
          DATA(mail) = cl_bcs_mail_message=>create_instance( ).
          DATA: recepient_email_address TYPE cl_bcs_mail_message=>ty_address.
          recepient_email_address = upgrade-email_address.
          mail->add_recipient( recepient_email_address ).
          mail->set_subject( 'Loyalty Program - Category Upgrade' ).

          " Build HTML body
          DATA(html) = |<!DOCTYPE html>| &&                 ##NO_TEXT
            |<html>| &&
            |<head>| &&
            |<style>| &&
            |  body \{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; \}| &&
            |  .container \{ max-width: 600px; margin: 0 auto; padding: 20px; \}| &&
            |  .header \{ background-color: #0070f3; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; \}| &&
            |  .content \{ background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; \}| &&
            |  .highlight \{ background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 20px 0; \}| &&
            |  .details \{ background-color: white; padding: 20px; margin: 20px 0; border-radius: 5px; \}| &&
            |  .badge \{ display: inline-block; padding: 5px 15px; border-radius: 20px; font-weight: bold; \}| &&
            |  .badge-old \{ background-color: #e0e0e0; color: #666; \}| &&
            |  .badge-new \{ background-color: #28a745; color: white; \}| &&
            |  .footer \{ text-align: center; margin-top: 30px; color: #666; font-size: 12px; \}| &&
            |</style>| &&
            |</head>| &&
            |<body>| &&
            |<div class="container">| &&
            |  <div class="header">| &&
            |    <h1>🎉 Congratulations!</h1>| &&
            |  </div>| &&
            |  <div class="content">| &&
            |    <h2>Your Loyalty Category Has Been Upgraded</h2>| &&
            |    <p>Dear Valued Customer,</p>| &&
            |    <div class="highlight">| &&
            |      <p><strong>Great news!</strong> Your loyalty points have reached a new milestone!</p>| &&
            |    </div>| &&
            |    <div class="details">| &&
*            |      <p><strong>Business Partner:</strong> { upgrade-business_partner }</p>| &&
*            |      <p><strong>Total Loyalty Points:</strong> { upgrade-total_points NUMBER = USER }</p>| &&
            |      <p style="margin-top: 20px;">| &&
            |        <strong>Previous Category:</strong> | &&
            |        <span class="badge badge-old">{ upgrade-old_category }</span>| &&
            |      </p>| &&
            |      <p>| &&
            |        <strong>New Category:</strong> | &&
            |        <span class="badge badge-new">{ upgrade-new_category }</span>| &&
            |      </p>| &&
            |      <p><strong>Membership ID:</strong> { upgrade-membership_id }</p>| &&
            |    </div>| &&
            |    <p>With your new <strong>{ upgrade-new_category }</strong> status, you now have access to enhanced benefits!</p>| &&
            |    <p>Thank you for your continued loyalty.</p>| &&
            |    <p>Best regards,<br>The Loyalty Hub Team</p>| &&
            |  </div>| &&
            |  <div class="footer">| &&
            |    <p>This is an automated message. Please do not reply.</p>| &&
            |    <p>&copy; { current_date+0(4) } Loyalty Hub. All rights reserved.</p>| &&
            |  </div>| &&
            |</div>| &&
            |</body>| &&
            |</html>|.

          mail->set_main( cl_bcs_mail_textpart=>create_text_html( html ) ).

          " Send email
          DATA(mail_status) = mail->send( ).

          " Optional: Get status
          mail_status->get_email_status(
            IMPORTING
              es_mail_status         = DATA(status_result)
              et_recipients_statuses = DATA(recipients_status)
          ).

        CATCH cx_bcs_mail INTO DATA(mail_error).
          " Log error but continue with other notifications
          CONTINUE.
      ENDTRY.

    ENDLOOP.

  ENDMETHOD.