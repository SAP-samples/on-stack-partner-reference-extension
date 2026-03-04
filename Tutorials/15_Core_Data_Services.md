# Core Data Services

## Overview
This tutorial describes the CDS artifacts used for the **Business Partner** domain object in a RAP application. The focus is on the **root CDS view**, the **associations**, the **projection view**, and the **behavior definition (BDEF)**.

---

## Root CDS View Entity

### Purpose
The root CDS view represents the main business partner entity. It combines core business partner data with sold-to information, exposes key fields, and declares all child compositions and associations used in the business object hierarchy.

### Key Annotations
- `@AccessControl.authorizationCheck: #MANDATORY`
- `@EndUserText.label: 'Business Partner Details'`
- `@Metadata.ignorePropagatedAnnotations: true`

```abap
define root view entity ZLH_R_BusinessPartner as select from I_BusinessPartner
inner join ZLH_I_SoldToParty as _SoldToParty on I_BusinessPartner.BusinessPartner =  _SoldToParty.SoldToParty
```

### Compositions and Associations
The root entity defines relationships to child entities:

**Compositions**
- `[0..1]` `_MemberShip` → `ZLH_R_Membership`
- `[0..*]` `_GiftCard` → `ZLH_R_GIFTCARD`
- `[0..*]` `_Transactions` → `ZLH_R_TRANSACTIONS`

```abap
composition [0..1] of ZLH_R_Membership as _MemberShip
composition [0..*] of ZLH_R_GIFTCARD as _GiftCard
composition [0..*] of ZLH_R_TRANSACTIONS as _Transactions
```
For reference, let's check gift card composition:
####  Giftcard
The relationship from business partner to gift card is modeled as a **composition with cardinality `[0..*]`**. This indicates a strong lifecycle dependency:

- Gift cards belong directly to a business partner.  
- Deleting the business partner typically deletes related gift cards.  
- RAP features this as create-on-association rely on this composition.

#### Importance
The composition ensures that gift card data remains bound to the correct business partner and stays consistent during transactional updates.

**Associations**
- `[0..*]` `_Category` → `ZLH_R_CATEGORY`  
- `[0..1]` `_UserBasic` → `I_BusinessUserBasic`
```abap
association [0..*] to ZLH_R_CATEGORY as _Category on $projection.SoldToParty = _Category.BusinessPartner
association [0..1] to I_BusinessUserBasic as _UserBasic on $projection.SoldToParty = _UserBasic.BusinessPartner
```

### Field Mapping
The projection list exposes key fields and descriptive fields:

```abap
key I_BusinessPartner.BusinessPartner as SoldToParty,
  I_BusinessPartner.BusinessPartnerName as CustomerName,
  I_BusinessPartner.AuthorizationGroup,
  I_BusinessPartner.LastChangeTime,
  _UserBasic.UserID,
  I_BusinessPartner.ETag,
  _MemberShip,
  _GiftCard,
  _Transactions,
  _Category,
  _UserBasic
  ```
  
---

## Projection View

### Purpose
The projection view adapts the root entity for consumption. It adds virtual elements, exposes UI-relevant fields, and redirects associations to consumption-layer views.

### Key Features
- Projection based on `ZLH_R_BusinessPartner` with `provider contract transactional_query`:
```abap
define root view entity ZLH_C_BusinessPartner
  provider contract transactional_query
  as projection on ZLH_R_BusinessPartner
  ```
- Virtual elements calculated in exit class `ZCL_LH_BP_CALC_EXIT`:
  - `MembershipCategory`
  - `TotalLoyaltyPointsAvailable`
  - `TotalLoyaltyPointsRedeemed`
  - `LltyPtsAvailableCriticality`
  - `LoyaltyMembershipCriticality`
- Association redirection:
  - `_GiftCard` → `ZLH_C_GIFTCARD`
  - `_MemberShip` → `ZLH_C_Membership`
  - `_Transactions` → `ZLH_C_TRANSACTIONS`
  - `_Category` → `ZLH_C_CATEGORY`
  ```abap
          _GiftCard     : redirected to composition child ZLH_C_GIFTCARD,
          _MemberShip   : redirected to composition child ZLH_C_Membership,
          _Transactions : redirected to composition child ZLH_C_TRANSACTIONS,
          _Category     : redirected to ZLH_C_CATEGORY
  ```

---

## Behavior Definition
A RAP behavior definition (BDEF) is an ABAP repository object that defines the transactional behavior of a RAP BO in the context of ABAP RAP. The transactional behavior defines and restricts how a RAP BO can be accessed by a RAP BO consumer. A BDEF is always based on a CDS data model that consists of at least one root entity and refers to this root entity. A root entity can only have one BDEF.

A RAP behavior definition includes two main components: a header part and at least one entity behavior definition. The entity behavior definition consists of entity characteristics and a body. You can optionally define one or more authorization contexts.

Let's take a look at one of the behavior definitions in detail.

### Behavior Definition for View Entity `ZLH_R_BusinessPartner`

The behavior definition for business partner declares all validations, determinations, actions, and attributes required for any application.

**RAP Behavior Definition Structure**

- **Behavior Definition Header**:
- `managed with additional save implementation in class ZCL_LH_AdditonalSave` unique - Specifies that the behavior implementation is managed by the framework, and the custom logic is placed in the specified ABAP class.
- `strict (2)` - Enforces **strict syntax checks** according to RAP strict mode version 2, promoting best practices and forward compatibility.
- `with draft` - Enables **draft handling**, allowing users to edit records in a temporary state before final activation.
- `total etag ETag` - Specifies the field used for optimistic locking to detect concurrent changes during the transition from draft to active data.
- `lock master` - Defines the root entity as the central locking object, ensuring exclusive access to the entire business object tree during modification.
- `authorization master (instance)` - Configures the entity to perform instance-based authorization checks and validating permissions against specific record data, for example a specific status or owner.
- `draft table zlh_d_buspartner` - Table used to store draft versions of records.

#### Operations and Field Settings
- Supported operations: `create (global)`, `update (global)`, `delete (global)`
- Read-only field: `SoldToParty`

#### Association Features
- `_GiftCard { create(precheck){ default function GetDefaultsForGiftCard; } with draft; }`
- `_MemberShip { create; with draft; }`
- `_Transactions { create(precheck); with draft; }`
- `_Category { with draft; }`

#### Actions
- `createMembership result [1] $self`
- `deleteMembership result [1] $self`
- `createCategory parameter ZLH_D_LHCREATECATEGORYP`

#### Draft Handling
The draft flow includes validation routines executed during the `Prepare` phase:

- `ZLH_R_TRANSACTIONS~validate_transaction_data`
- `ZLH_R_GIFTCARD~validateGiftCardFields`
- `ZLH_R_GIFTCARD~validateGiftcardBalance`

Additional draft actions: `Activate`, `Resume`, `Discard`

#### Side Effects
- `createMembership` → affects `_Category`
- `createCategory` → affects `_Category`
- `deleteMembership` → affects `_GiftCard`, `_Category`

#### Notes on Behavior of Child Entities
Child entities define their own specific rules, validations, and number generation logic.

> [!NOTE]
> For more information, refer to [RAP - EntityBehaviorBody](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENBDL_BODY.html) and [ABAP RAP Behavior Definition](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENBDL.html).

### Projection Behavior Definition

A RAP projection BO prepares a business object for a specific business service. The projection enables flexible service consumption and role-based service design. In RAP, a projection BO consists of CDS projection views, RAP projection behavior definitions, and, if needed, additional or consumption-specific implementations.

#### Projection Behavior Definition for `ZLH_C_BusinessPartner`

Go to [Projection Behavior for Business Partner](../objects/BDEF/ZLH_C_BUSINESSPARTNER/REPS%20ZLH_C_BUSINESSPARTNER=========BD.abap) to learn how actions and associations are defined.

> [!NOTE]
> For more information about projection behavior definitions, refer to [RAP - Projection Behavior Definitions](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENBDL_PROJECTION_BO.html).

## Metadata Extension

In SAP BTP ABAP RESTful Application Programming Model, a metadata extension is a way to annotate CDS views externally, providing UI-related annotations without modifying the original CDS view itself. This is particularly useful when you want to enrich the UI presentation layer, for example, how fields are shown in SAP Fiori elements applications without touching the base CDS artifacts. This maintains separation of concerns and enhances reusability. For a reference of a sample application, see [Enhance the Business Object Data Model and Enable OData Streams](https://developers.sap.com/tutorials/abap-environment-rap100-enhance-data-model.html?utm_source=chatgpt.com).

To extend a CDS entity with metadata extensions, you need to specify the **@Metadata.allowExtensions** annotation in the DDL source code of the CDS entity. The default value for this annotation is *true*.

For more information, refer to [Metadata extension for Business partner](../objects/DDLX/ZLH_E_BUSINESSPARTNER).
