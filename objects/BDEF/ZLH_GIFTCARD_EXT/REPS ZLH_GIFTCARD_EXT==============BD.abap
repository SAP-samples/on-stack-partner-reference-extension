extension using interface i_salesordertp
implementation in class zcl_lh_giftcard_ext unique;

extend own authorization context  {
'ZLOYLTYHUB';
}
extend behavior for SalesOrder
{

  action ( authorization : update , features : instance ) zz_use_gift_card

    parameter ZLH_D_AssignGiftCardToSO result [0..1] $self;

  field(readonly) zz_giftcardamount_sdh, zz_giftcardcurrency_sdh;

  side effects {
    action zz_use_gift_card affects entity _Item, entity _PricingElement;

  }

}