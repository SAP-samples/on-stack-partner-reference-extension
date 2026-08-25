# Changes


## Current Version - August 2026

The tutorials and the **Loyalty Hub** sample reference application code are available in the `main` branch.

The current version includes:

- **[Reactivate Membership](./Tutorials/14_Develop_Business_Logic.md#representative-action-reactivatemembership):** Reactivates an inactive membership and its latest category, restoring both to active status.
- **Semantic Color Coding for Loyalty Points:** In the **Transaction** section, credited points appear in green with a plus sign, while deducted points appear in red with a minus sign for clearer visual distinction.
- **ABAP Unit Tests:** ABAP Unit tests (AUnits) are created for the application objects to validate the business logic. The following test classes are implemented:

| Test Class | What the tests verify |
| --- | --- |
| [`ltcl_bp_calc_exit`](./objects/CLAS/ZCL_LH_BP_CALC_EXIT/CINC%20ZCL_LH_BP_CALC_EXIT===========CCAU.abap) | Calculated business partner fields — membership and loyalty-point criticality, latest category resolution, and requested calculation elements. |
| [`ltcl_bp_behavior_handler`](./objects/CLAS/ZCL_LH_BUSINESSPARTNER/CINC%20ZCL_LH_BUSINESSPARTNER========CCAU.abap) | Business partner behavior — membership early numbering, instance features, and creating or deleting membership. |
| [`ltcl_category_behavior_handler`](./objects/CLAS/ZCL_LH_BUSINESSPARTNER/CINC%20ZCL_LH_BUSINESSPARTNER========CCAU.abap) | Category creation through business partner, including duplicate detection and threshold checks. |
| [`ltcl_category_filldefaults`](./objects/CLAS/ZCL_LH_CATEGORY/CINC%20ZCL_LH_CATEGORY===============CCAU.abap) | Category default values — defaulting of initial fields, preservation of existing values, and deactivation logic. |
| [`ltcl_category_update_job`](./objects/CLAS/ZCL_LH_CATEGORY_UPDATE_JOB/CINC%20ZCL_LH_CATEGORY_UPDATE_JOB====CCAU.abap) | Category upgrade job — execution flow, application logging, upgrade eligibility processing, category creation, and email notifications. |
| [`ltcl_giftcard_handler`](./objects/CLAS/ZCL_LH_GIFTCARD/CINC%20ZCL_LH_GIFTCARD===============CCAU.abap) | Gift card create defaults, field and balance validations, update prechecks, and instance feature control. |
| [`ltcl_giftcard_api`](./objects/CLAS/ZCL_LH_GIFTCARD_API/CINC%20ZCL_LH_GIFTCARD_API===========CCAU.abap) | Gift card balance read (active/inactive, overflow cap) and redemption logic (partial, multi-card, FIFO, insufficient balance). |
| [`ltc_gc_logic`](./objects/CLAS/ZCL_LH_GIFTCARD_EXT/CINC%20ZCL_LH_GIFTCARD_EXT===========CCAU.abap) | Sales order gift card evaluation — balance, sales-order amount, minimum threshold, and redemption error handling. |
| [`ltcl_loyalty_points`](./objects/CLAS/ZCL_LH_LOYALTY_POINTS/CINC%20ZCL_LH_LOYALTY_POINTS=========CCAU.abap) | Loyalty point calculation across activity types and membership status, plus point normalization boundaries. |
| [`ltcl_membership_determination`](./objects/CLAS/ZCL_LH_MEMBERSHIP/CINC%20ZCL_LH_MEMBERSHIP=============CCAU.abap) | Membership creation does not auto-create a category when no default category exists. |
| [`ltcl_transaction_handler`](./objects/CLAS/ZCL_LH_TRANSACTIONS/CINC%20ZCL_LH_TRANSACTIONS===========CCAU.abap) | Transaction loyalty calculation, validation, instance features, default values, and update prechecks. |
| [`ltc_salesorder_integration`](./objects/CLAS/ZLH_SALESORDER_INTEGRATION/CINC%20ZLH_SALESORDER_INTEGRATION====CCAU.abap) | Sales order create/update events — building loyalty transaction payloads and skipping incomplete or existing records. |

## March 2026 (Initial Version)

The tutorials and the **Loyalty Hub** sample reference application code are available in the `main` branch.

### Highlights

- Comprehensive, step-by-step tutorials for building, running, and integrating an on-stack extension on **SAP S/4HANA Cloud Public Edition** using the ABAP RESTful Application Programming Model (RAP).
- Ready-to-run sample code for the **Loyalty Hub** application, delivered as a multi-off on-stack extension.
- Guidance on best practices for ABAP RAP, Core Data Services (CDS), SAP Fiori elements, and clean-core integration with SAP S/4HANA Cloud Public Edition.

### Tutorials Provided

- Developing an on-stack extension in SAP S/4HANA Cloud Public Edition with ABAP RAP, including data modeling and OData service generation.
- Implementing business logic, business configuration, and role-based authorization for the RAP application.
- Setting up event-based integration between the Loyalty Hub and the **Manage Sales Orders – Version 2** application, including the gift card scenario.
- Extending the user interface using freestyle SAPUI5 or SAP Fiori elements, with navigation links and semantic actions.
- Using reuse services such as number ranges, application jobs, email notifications, and message logging.

### Additional Notes

- All tutorials are located in the [`Tutorials`](./Tutorials) directory.
- Refer to the [README.md](./README.md) for an overview and navigation help.
- For a quick deployment, see the [Quick Start Guide](./Tutorials/10_Quick_Start_Guide.md).
