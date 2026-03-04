
# Develop Business Logic

In the previous step, as part of the creation of the behavior definition, you have already defined the standard operations. In this step, you will learn how to develop additional business logic with actions, determination, validations, etc.

## Overview

The **Business Partner** entity (ZLH_R_BusinessPartner) serves as the **root** of the business object. The application uses:

- **Managed behavior** with **additional save implementation** in the `ZCL_LH_AdditonalSave` class
- **Draft-enabled** behavior across all entities
- Multiple child entities associated with the root: 
    - **Membership**
    - **Gift Card**
    - **Transactions**

- Category is the child entity associated to Membership.

Additional logic is implemented using **actions**, **validations**, and **determinations** across these entities. Projection behaviors expose the required operations to the UI.

---

## Entity Relationships

The business object consists of one root entity and four related entities:

### Root Entity

- **Business Partner (ZLH_R_BusinessPartner)**
    - Exposes instance actions
    - Provides create-on-association to children
    - Defines draft actions and prepares validations

### Child Entities

- **Membership (ZLH_R_Membership)** - created through association from Business Partner
- **Gift Card (ZLH_R_GIFTCARD)**
- **Transactions (ZLH_R_TRANSACTIONS)**
- **Category (ZLH_R_CATEGORY)** - associated to Membership

### Behavior Highlights

- All child entities are **locked and authorized dependent by _BP**.
- All entities have draft tables.
- **Side effects** are defined, for example: 
    - Actions affecting Category or GiftCard
    - Fields affecting messages or recalculations

Relationships between entities ensure consistent master–detail behavior in the UI.

---

## Actions

RAP **actions** execute custom logic that modifies the state of an entity. You must implement custom logic in the RAP handler method FOR MODIFY.

Creating an action involves the following steps:

1. **Define the action in the behavior definition**: Specify the action's name, parameters, and when it should be triggered.
2. **Expose the action in the BO projection layer**: Make the action available for consumption in the OData service.
3. **Implement the action logic**: Write the ABAP code that defines what happens when the action is executed.


### Representative Action: createMembership

This instance-bound action creates a Membership entry for a Sold-toParty using create-on-association.
#### Explanation

The action uses EML to create a Membership row under the Business Partner. Default values such as `MemberSince`, `MembershipStatus`, and `MembershipEndDate` are set automatically. The updated BP instance is returned as the action result.

Let's create this action:
1. Navigate to the behavior definition of Loyalty Hub, for example **ZLH_R_BusinessPartner**.
2. Add the action name and trigger point to the behavior definition:

```
action ( features : instance ) createMembership result [1] $self;
```
3. Hover over the action name and press Ctrl+1 (Windows) or Command+Shift+1 (Mac) to open the **Quick Assist** view. Then, choose **Add method for action createMembership...**. As a result, the method for the **createMembership** action is added to the local handler class, *lcl_handler*, in the behavior pool of the Business Partner entity.
4. Add the implementation for an action. Refer to [CreateMembership action](../objects/CLAS/ZCL_LH_BUSINESSPARTNER/CINC%20ZCL_LH_BUSINESSPARTNER========CCIMP.abap) for more information.

 5. Save and activate the action.

You can now test the action to see if a user is able to create a membership in the app.

 ### Action on the UI
To make the action visible on the UI, add the following code snippet to the metadata extension of any UI facet.
```abap
@UI.identification:
[
    {type: #FOR_ACTION, 
    dataAction: 'createMembership', 
    label: 'Create Membership',position: 10 }
]
```

### Action Availability in the Projection Behavior  
To make the action available to use, you need to make it available in the projection behavior for Business Partner, **ZLH_C_BusinessPartner**. Therefore, add the below code snippet:
```abap
  use action createMembership;
```

#### More Actions

Other implemented actions are:

- `deleteMembership`
- `createCategory`

> All actions can be found in [Behavior Definition](../objects/BDEF/ZLH_R_BUSINESSPARTNER/REPS%20ZLH_R_BUSINESSPARTNER=========BD.abap).

### More Information

- [Actions on SAP Help Portal](https://help.sap.com/docs/abap-cloud/abap-rap/actions?locale=en-US&version=sap_btp)
- [Actions ABAP EML](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENBDL_ACTION.html)
- Examples of developing actions:
  - [Flight Scenario](https://help.sap.com/docs/abap-cloud/abap-rap/developing-actions?version=sap_btp)
  - [RAP100](https://github.com/SAP-samples/abap-platform-rap100/tree/main/exercises/ex06)
- [Implementation Contract](https://help.sap.com/docs/abap-cloud/abap-rap/implementation-contract-action?version=sap_btp)
---

## Validations

A RAP validation checks the consistency of RAP BO instances based on trigger conditions. The RAP framework automatically invokes a validation if the trigger condition is fulfilled. Validations can be triggered by operations, fields, or both.

Creating a validation involves two main steps:

1. **Define the validation in the behavior definition**: Specify when the validation should be triggered.
2. **Implement the validation logic**: Write the code that is executed when the validation is triggered.

>Note: Front-end and back-end validations ensure data consistency. As the names suggest, front-end validations are performed on the UI. They improve the user experience by providing faster feedback and avoiding unnecessary roundtrip. In the RAP context, front-end validations are defined using CDS annotations or UI logic. Back-end validations are performed on the back end. They are defined in the business object behavior definition and implemented in the respective behavior pools. Front-end validations can be easily bypassed, for example, by using EML APIs in the RAP context. Therefore, back-end validations are essential for ensuring data consistency. This document focuses on back-end validations.

### Representative Validation: validate_transaction_data

This validation runs on save (create/update) of the Transaction entries.
#### Explanation

The validation prevents saving transactions with invalid data, for example, when required fields contain zero or inconsistent values. It reports messages and marks the failing instances.

Let's create this validation:
1. Navigate to the behavior definition of the Loyalty Hub, for example **ZLH_R_BusinessPartner**.
2. Add a validation name and trigger point to the behavior definition:
```abap
validation validate_transaction_data on save { create; update; field TransactionDate, LoyaltyPoints, PointExpiryDate; }
```
3. Hover over the validation name and press Ctrl+1 (Windows) or Command+Shift+1 (Mac) to open the Quick Assist view. Then, choose **Add method for validation validate_transaction_data...**.
4. As a result, a method for the validation named **validate_transaction_data** is added to the local handler class *lcl_handler* of the behavior pool of the Transactions entity.
5. Add the implementation for the validation. Refer to [validate_transaction_data](../objects/CLAS/ZCL_LH_TRANSACTIONS/CINC%20ZCL_LH_TRANSACTIONS===========CCIMP.abap) for more information.
6. Save and activate the validation.

You can now test the validation.
   
#### More Validations

Gift card behavior includes:

- `validateGiftCardFields`
- `validateGiftcardBalance`

> All validations can be found in [Behavior Definition](../objects/BDEF/ZLH_R_BUSINESSPARTNER/REPS%20ZLH_R_BUSINESSPARTNER=========BD.abap).

### More Information

- [Validations on SAP Help Portal](https://help.sap.com/docs/abap-cloud/abap-rap/validations)
- [Validations ABAP EML](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENBDL_VALIDATIONS.html)
- Examples of developing validations: 
  - [Flight Scenario](https://help.sap.com/docs/abap-cloud/abap-rap/developing-validations?version=sap_btp)
  - [RAP100](https://github.com/SAP-samples/abap-platform-rap100/tree/main/exercises/ex05)

## Determinations

A determination modifies instances of RAP business objects based on trigger conditions. A determination is implicitly invoked by the RAP framework if the trigger condition of the determination is fulfilled. Determinations can be triggered by trigger operations, trigger fields, or both.

Creating a determination involves two main steps:

1. **Define the determination in the behavior definition**: This is where you specify when the determination should be triggered.
2. **Implement the determination logic**: This is where you write the code that is executed when the determination is triggered.

### Representative Determination: setGiftcardBalanceOnCreate
Triggered during modify/create of a gift card when `GiftCardValue` changes.
#### Explanation

This determination ensures balance values are initialized consistently based on `GiftCardValue` immediately after creation.

For reference, let's create this determination:
1. Navigate to the behavior definition of the Loyalty Hub, for example **ZLH_R_BusinessPartner**.
2. Add a validation name and trigger point to the behavior definition:
```abap
determination setGiftcardBalanceOnCreate on modify { field GiftCardValue; create; }
```
3. Once done, hover over the determination name you've created and press Ctrl+1 (Windows)/Command+shift+1 (Mac) to open the Quick Assist view and choose **Add method for determination setGiftcardBalanceOnCreate...**. As a result, the method for the **setGiftcardBalanceOnCreate** determination is added to the local handler class *lcl_handler* in the behavior pool of the GiftCards entity.
4. Add the implementation for the determination. Refer to [determination setGiftcardBalanceOnCreate](../objects/CLAS/ZCL_LH_GIFTCARD/CINC%20ZCL_LH_GIFTCARD===============CCIMP.abap) for more information.
5. Save and activate the determination.

You can test the determination in the app to check if the available balance field is updated correctly on the **Giftcard** tab.

#### More Determinations

Other determinations include:

- `LoyaltyPointCalculations` on Transactions
- `fillDefaultValues` on Category and Membership

>  All validations can be found in [Behavior Definition](../objects/BDEF/ZLH_R_BUSINESSPARTNER/REPS%20ZLH_R_BUSINESSPARTNER=========BD.abap).

### More Information

- [Determinations on SAP Help Portal](https://help.sap.com/docs/abap-cloud/abap-rap/determinations)
- [Determinations ABAP EML](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENBDL_DETERMINATIONS.html)
- Detailed developing determinations example:
  - [Flight Scenario](https://help.sap.com/docs/abap-cloud/abap-rap/developing-determinations?version=sap_btp)
  - [RAP100](https://github.com/SAP-samples/abap-platform-rap100/tree/main/exercises/ex04)

---

## Projection Behavior

Projections (`ZLH_C_*`) control which operations and fields are available on the UI.

### Key Elements

- **Draft actions** such as `Edit`, `Prepare`, `Activate`, and others are available for business partners.
- **Associations** are enabled with create-on-association for:
    - `_GiftCard`
    - `_MemberShip`
    - `_Transactions`
- **Read-only fields** are enforced in projection for: 
    - GiftCard (e.g., balance, status)
    - Transactions (amount, currency, etc.)

### Declaration Example

```
use action createMembership;
use association _GiftCard { create; with draft; }
```

---

## Full Implementation References

- [Behavior pool for Business Partner](../objects/CLAS/ZCL_LH_BUSINESSPARTNER/CINC%20ZCL_LH_BUSINESSPARTNER========CCIMP.abap)
- [Behavior pool for GiftCard](../objects/CLAS/ZCL_LH_GIFTCARD/CINC%20ZCL_LH_GIFTCARD===============CCIMP.abap)
- [Behavior pool for Membership](../objects/CLAS/ZCL_LH_MEMBERSHIP/CINC%20ZCL_LH_MEMBERSHIP=============CCIMP.abap)
- [Behavior pool for Category](../objects/CLAS/ZCL_LH_CATEGORY/CINC%20ZCL_LH_CATEGORY===============CCIMP.abap)
- [Behavior pool for Transactions](../objects/CLAS/ZCL_LH_TRANSACTIONS/CINC%20ZCL_LH_TRANSACTIONS===========CCIMP.abap)
