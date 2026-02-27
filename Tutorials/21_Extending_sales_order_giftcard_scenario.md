
# SAP RAP: Sales Order Gift Card Extension (ZLH_*) — End‑to‑End Tutorial
In this tutorial you learn how to extend a sales order in SAP S/4HANA Cloud Public Edition to support the redemption of a gift card. For more information, see [Extending Sales Order RAP BO for the Gift Card Scenario](https://help.sap.com/docs/SAP_EXTENSIBILITY_EXPLORER/c87ef8f108e147d6b7143fd3c0fb1459/5806f5bf62c4487985b68c1e915b662c.html?locale=en-US) on SAP Help Portal.

> **What you'll build:**
> * Action `zz_use_gift_card` on `SalesOrder` that validates, redeems, and posts a negative pricing condition.
> * **Use Gift Card** UI button on the **Manage Sales Orders** UI with gift card fields.
> * **amount** and **currency** as persistent fields for the gift card in a sales order.

---

## Repository Structure
```
/README.md                      ← this tutorial
/src/
  ZLH_SalesOrder_Append.abap    ← Append structure to SDSALES* incl. type
  ZLH_E_SalesDocument_EXT.abap  ← E_SalesDocumentBasic extension
  ZLH_R_SalesOrderTP_EXT.abap   ← R_SalesOrderTP extension
  ZLH_I_SalesOrderTP_EXT.abap   ← I_SalesOrderTP extension
  ZLH_GiftCard_EXT.bdef         ← Behavior extension (BDEF)
  zcl_lh_giftcard_ext.clas.abap ← Behavior handler (CLAS)
  ZLH_C_SalesOrderManage_EXT.abap ← Projection (C_SalesOrderManage) extension
/test/
  zcl_lh_giftcard_ext_test.abap ← EML unit tests (optional)
/docs/
  architecture.md               ← diagrams & flow (optional)
```



---

## 1) Persistency — Append Gift Card Fields
Create an **append to the Sales Order include** to persist amount and currency.

```abap
ZLH_SalesOrder_Append
@EndUserText.label : 'Sales Order Extension for Gift Card Fields'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
extend type sdsalesdoc_incl_eew_ps with zlh_salesorder_append {

  @Semantics.amount.currencyCode : 'zlh_salesorder_append.zzlh_giftcardcurrency_sdh'
  zzlh_giftcardamount_sdh   : zlh_giftcardamt;
  zzlh_giftcardcurrency_sdh : abap.cuky;
}
```

> Keep the `zzlh_giftcardamount_sdh` type compatible with your pricing condition type (for example, `CURR(15,2)`) and the API signature to avoid dumps.

---

## 2) Exposure — Extend E/R/I Views of Sales Order
Expose the new fields through the RAP view entities and carry a foreign key association to `I_Currency` for value help and semantics.


[ZLH_E_SalesDocument_EXT](../objects/DDLS/ZLH_E_SALESDOCUMENT_EXT/DDLS%20ZLH_E_SALESDOCUMENT_EXT.asx.json).
```abap
extend view entity E_SalesDocumentBasic
  with association [0..1] to I_Currency as _zz_giftcardcurrency_sdh
    on $projection.zz_giftcardcurrency_sdh = _zz_giftcardcurrency_sdh.Currency {

  @Semantics.amount.currencyCode: 'zz_giftcardcurrency_sdh'
  Persistence.zzlh_giftcardamount_sdh  as zz_giftcardamount_sdh,

  @ObjectModel.foreignKey.association: '_zz_giftcardcurrency_sdh'
  Persistence.zzlh_giftcardcurrency_sdh as zz_giftcardcurrency_sdh,

  _zz_giftcardcurrency_sdh
}
```


[ZLH_R_SalesOrderTP_EXT](../objects/DDLS/ZLH_R_SALESORDERTP_EXT/DDLS%20ZLH_R_SALESORDERTP_EXT.asx.json).
```abap
extend view entity R_SalesOrderTP with {
  @Semantics.amount.currencyCode: 'zz_giftcardcurrency_sdh'
  _Extension.zz_giftcardamount_sdh   as zz_giftcardamount_sdh,
  _Extension.zz_giftcardcurrency_sdh as zz_giftcardcurrency_sdh
}
```


[ZLH_I_SalesOrderTP_EXT](../objects/DDLS/ZLH_I_SALESORDERTP_EXT/DDLS%20ZLH_I_SALESORDERTP_EXT.asx.json).
```abap
extend view entity I_SalesOrderTP with {
  @Semantics.amount.currencyCode: 'zz_giftcardcurrency_sdh'
  SalesOrder.zz_giftcardamount_sdh   as zz_giftcardamount_sdh,
  SalesOrder.zz_giftcardcurrency_sdh as zz_giftcardcurrency_sdh
}
```

---

## 3) Behavior — Action and Field Control
Declare the custom action, read-only display of fields, side effects, and authorization context.
[ZLH_GiftCard_EXT](../objects/BDEF/ZLH_GIFTCARD_EXT/REPS%20ZLH_GIFTCARD_EXT%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3DBD.abap).
```abap
extension using interface i_salesordertp
implementation in class zcl_lh_giftcard_ext unique;

extend own authorization context {
  'ZLOYLTYHUB';
}

extend behavior for SalesOrder {

  action ( authorization : update , features : instance ) zz_use_gift_card
    parameter ZLH_D_AssignGiftCardToSO result [0..1] $self;

  field(readonly) zz_giftcardamount_sdh, zz_giftcardcurrency_sdh;

  side effects {
    action zz_use_gift_card affects entity _Item, entity _PricingElement;
  }
}
```

> **Note:** Marking the gift card fields `readonly` means they are **display-only**. User input (and therefore F4) is on the **action parameter** if you include currency/ID there. For more information, see the **Enabling F4 (Value Help) - Currency and Gift Card** section below.

---

## 4) Behavior Handler — Implementation
Class [`zcl_lh_giftcard_ext`](../objects/BDEF/ZLH_GIFTCARD_EXT/REPS%20ZLH_GIFTCARD_EXT%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3D%3DBD.abap) (object name: handler subclass `lhc_salesorder`).


---

## 5) UI — Projection View Extension
Add a **Use Gift Card** button on the pbject page and expose the value help association.


[ZLH_C_SalesOrderManage_EXT](../objects/DDLS/ZLH_C_SALESORDERMANAGE_EXT/DDLS%20ZLH_C_SALESORDERMANAGE_EXT.asx.json)
```abap
@EndUserText.label: 'Sales Order Projection View Extension'
extend view C_SalesOrderManage with ZLH_C_SALESORDERMANAGE_EXT
  association [0..1] to I_Currency as _zz_giftcardcurrency_sdh
    on $projection.zz_giftcardcurrency_sdh = _zz_giftcardcurrency_sdh.Currency {

  @Semantics.amount.currencyCode: 'zz_giftcardcurrency_sdh'
  @UI: { fieldGroup:[{ qualifier: 'OrderData', importance: #HIGH,
                       type: #FOR_ACTION, dataAction: 'zz_use_gift_card',
                       label: 'Use Gift Card' }] }
  @UI.lineItem: [{ position: 65, importance:#HIGH }]
  SalesOrder.zz_giftcardamount_sdh   as zz_giftcardamount_sdh,

  @ObjectModel.foreignKey.association: '_zz_giftcardcurrency_sdh'
  SalesOrder.zz_giftcardcurrency_sdh as zz_giftcardcurrency_sdh,

  _zz_giftcardcurrency_sdh
}
```

---

## 6) Enabling F4 (Value Help) — Currency and Gift Card
You noted that **there is no F4 help**. Here’s how to enable it depending on where user input occurs:

### F4 for **Currency** (on the persisted field)
1. Keep the **foreign key association** to `I_Currency` (already done).
2. In the **projection** that renders the field, make sure the field is **editable**. Because the behavior marks it `readonly`, users cannot trigger F4 on the field itself. If user input is not intended here, skip and implement value help on the **action parameter** instead.
3. If you still want F4 while keeping persistency read‑only, add currency to the **action parameter** and annotate the parameter with value help.

### F4 for **Action Parameter** (recommended)
Add `giftcardcurrency` (and optionally `giftcardid`) to the [`ZLH_D_AssignGiftCardToSO`](../objects/DDLS/ZLH_D_ASSIGNGIFTCARDTOSO/DDLS%20ZLH_D_ASSIGNGIFTCARDTOSO.asx.json) parameter and annotate:

```abap
@EndUserText.label: 'Assign Gift Card to Sales Order'
define structure ZLH_D_AssignGiftCardToSO {
  @Semantics.amount.currencyCode: 'giftcardcurrency'
  giftcardamount  : zlh_giftcardamt;
}
```



### F4 for **Gift Card ID list** (popover)
If your UX requires users to select from the **available gift cards**, expose a value help entity bound to your API/backing table and annotate the parameter `giftcardid` similarly. On execution, resolve the `giftcardid` → amount/currency server‑side.

---

## 7) Pricing — Post a Negative Condition
The handler creates a pricing element with condition type **`DRV1`** and a negative rate equal to the redeemed amount. Adapt the condition type to your configuration if needed.

---

## 8) Authorizations
- Action runs under the `ZLOYLTYHUB` authorization context. Provide or update the roles granting **update** rights on the sales order BO and access to your Gift Card API/service.
- If testers face authorization errors on **Use Gift Card**, check the role assignment in the target system and include the role list in your project docs.

---

## 9) Test and Demo
- **Preview the App (SAP Fiori elements):** Open the **Manage Sales Orders** app, pick a test order, and choose **Use Gift Card**.
- **Unit Tests (EML):**
  - *Positive:* gift card amount ≤ balance and ≤ SO net value.
  - *Negative:* amount 0; amount > balance; amount > SO net value; SO net value < 50; API redeem failure.
- **Verify:** Persisted fields updated; pricing element created; messages displayed from `ZPRA_LOYALTYHUB`.

---

## 10) Troubleshooting
- **Activation/Extension errors** when using fields from other extensions:
  - Ensure your **E/R/I** view extensions are **active** before the **BDEF** that references them.
  - Keep object names consistent and avoid referencing fields not yet projected.
- **Type mismatch dumps:** Align `giftcardamount` types across API, parameter, persistency, and pricing condition (for example, use `CURR(15,2)` end to end).
- **No F4 for currency:** The field is `readonly`. Move the input to the action parameter and annotate with `@Consumption.valueHelpDefinition` or make the field editable in the UI layer.
- **Authorization errors on action:** Verify roles and authorizations contexts and back-end checks in `zcl_lh_giftcard_api`.

---

## 11) Appendix — Message Catalog
Use your `ZPRA_LOYALTYHUB` message class:
- **001** — Amount exceeds available gift card balance
- **018** — Amount exceeds sales order net value
- **019** — Sales order net value below threshold
- **000** — Amount is zero
- **003** — Gift card redemption failed

---


## Gift Card API 

This section explains the `ZCL_LH_GIFTCARD_API` gift card API class that backs the `zz_use_gift_card` sales order action.  
It covers the public methods, parameters, errors, and example usage in the behavior handler.

---

### Purpose

- Provide an application service for reading total gift card balance for a business partner.
- Provide an application service to redeem an amount using a FIFO strategy across active cards.
- Encapsulate RAP EML reads/updates to the GiftCard composition under the business partner.
- Surface domain errors by raising the `ZCX_LH_GIFTCARD` exception class.

---

### Public Interface
Below are two public methods provided by the class:

**`read_gift_card_balance`**

- **Input:** `business_partner`  
- **Output:** `total_balance` (sum of active cards), `currency` (last active card’s currency; system assumes homogeneous currency)  
- **Errors:** Raises `ZCX_LH_GIFTCARD=>no_gift_cards` if no active cards are found.  
- **Notes:**
  - Uses RAP `READ ENTITIES` on the business partner root to navigate to `_GiftCard`.
  - Sums `GiftcardBalance` for cards with `GiftcardStatus = active`.
  - Caps at `zif_lh_constants=>max_giftcard_value`.

**Example call:**

    zcl_lh_giftcard_api=>read_gift_card_balance(
      EXPORTING business_partner = salesorder_detail-SoldToParty
      IMPORTING total_balance    = available_gc_balance
                currency         = available_gc_currency ).

#### `redeem_gift_card_amount`

- **Input:** `business_partner`, `amount`, `currency`  
- **Output:** `new_balance` after redemption  
- **Errors:**
  - `insufficient_balance` if requested amount exceeds current total.
  - Generic exception on update failure (for example locks or validations).
- **Behavior:**
  - Recomputes current total.
  - Reads all active cards for the partner, sorts by `CreatedOn` (FIFO).
  - Iteratively reduces `GiftcardBalance` across cards using `nmin(...)`.
  - Performs RAP `MODIFY ENTITIES` to update balances in one transaction.
- **Post‑condition:**
  - `new_balance = current_total - amount`.

**Example call:**

    zcl_lh_giftcard_api=>redeem_gift_card_amount(
      EXPORTING business_partner = salesorder_detail-SoldToParty
                amount           = giftcard_amount
                currency         = salesorder_detail-TransactionCurrency
      IMPORTING new_balance      = DATA(updated_total) ).

---

### Handler Integration 

The pattern in the behavior handler `lhc_salesorder` is as follows:

- Read sales order facts (currency, net amount, completion status).
- Call `read_gift_card_balance`.
- Validate the amount against available balance and SO net amount.
- Call `redeem_gift_card_amount`.
- Update the SO extension fields and create negative pricing condition.
- Report messages on failure paths.



---

### Error Handling and Messages

- API raises [`ZCX_LH_GIFTCARD`](../objects/CLAS/ZCX_LH_GIFTCARD/) for domain errors (for example no cards, insufficient balance, or update failures).
- Handler converts exceptions into RAP-reported messages (for example message class `ZPRA_LOYALTYHUB` or numbers `001/018/019/000/003`).
- Failure appends to `failed-salesorder` and adds error messages to `reported-salesorder`.
