# Create a Business Configuation Maintenance Object for Maintaining Categories

When a membership is created for a Sold-to Party, a corresponding membership category must also be assigned. These membership categories need to be defined during the initial setup of the application.

To define and maintain the categories, a **Business Configuration Maintenance Object** can be created. This generates a service binding that can then be maintained using the **Custom Business Configurations** app.

## Overview

This tutorial explains how to create a **business configuration maintenance object** for a database table for maintenance using the **Custom Business Configurations** app. A [business configuration maintenance object](https://help.sap.com/docs/btp/sap-business-technology-platform/business-configuration-maintenance-object?version=Cloud) declares a service binding as relevant for business configuration and is shown on the list of all maintainable business configurations in the **Custom Business Configurations** app. It is maintained via API or ADT.

## Create Data Elements

Create the required data elements from the table below. They're required during table creation to store the category details.

| Data Element         | Description             |  Type | Length |
| -------------------- | ----------------------- | ----- | ------ |
| ZLH_CATEGORY_ID      | Category ID             | NUMC  |      8 |
| ZLH_ENABLED          | Enabled                 | CHAR  |      1 |
| ZLH_DEFAULT          | Default                 | CHAR  |      1 |
| ZLH_CATEGORY_MIN_PT  | Category Minimum points | INT8  |     19 |
| ZLH_APPROVER         | Approver                | CHAR  |     12 |
| ZLH_CONVERSION_VALUE | Conversion value        | DEC   |    4,2 |
| ZLH_CREATED_ON       | Created On              | DATS  |      8 |
| ZLH_CREATED_BY       | Created By              | CHAR  |     12 |
| ZLH_LASTCHANGED_AT   | Last Changed At         | DATS  |      8 |
| ZLH_LASTCHANGED_BY   | Last Changed By         | CHAR  |     12 |
| ZLH_CATEGORY_NAME    | Artist                  | CHAR  |     50 |
| ZLH_CATEGORY_DESC    | Category Description    | CHAR  |    100 |

## Create Database Tables

Create database tables to store category headers and text details. Use these tables as the basis for the creation of the business configuration maintenance object. The header table includes the following fields: 

- Category ID
- Enabled status
- Default category indicator
- Threshold
- Conversion value

## Create a Category Header Table

1. Right-click on your ABAP package and choose **New > Other ABAP Repository Object**.
2. Search for database table, select it, and choose **Next**.
3. Maintain the required information and choose **Next**.
   - **Name**: ZLH_CATEGORY_HDR
   - **Description**: Loyalty Hub Category Header
4. Select a transport request and choose **Finish** to create the database table.
5. For details of the table refer [ZLH_CATEGORY_HDR](../objects/TABL/ZLH_CATEGORY_HDR/TABL%20ZLH_CATEGORY_HDR.asx.json).
6. Save and activate the changes.

## Create a Category Text Table

1. You can create a text table by following the steps provided above and maintaining the following information:

   - **Name**: ZLH_CATEGORY_TXT
   - **Description**: Loyalty Hub Category Text
2. For details of the table refer [ZLH_CATEGORY_TXT](../objects/TABL/ZLH_CATEGORY_TXT/TABL%20ZLH_CATEGORY_TXT.asx.json).

## Create Business Configuration Maintenance Object

You can follow the steps below or refer to this tutorial in the Tutorial Navigator on SAP Learning: [Create a SAP Fiori based Table Maintenance app with SAP BTP, ABAP Environment](https://developers.sap.com/group.abap-env-factory.html)

1. Right-click on the `ZLH_CATEGORY_HDR` database table and choose **Generate ABAP Repository Objects…**.
2. Select `Maintenance Object` and choose **Next >**.
3. Enter the package and choose **Next >**.
4. The system generates a proposal for all input fields based on the description of the table by following these [naming conventions](https://help.sap.com/docs/abap-cloud/abap-rap/naming-conventions-for-development-objects?version=sap_btp). If you receive an error message stating that a specific object already exists, change the corresponding name in the wizard.
5. The list of repository objects that are generated is displayed. Choose **Next >**.
6. Select a transport request and choose **Finish.**

When the generation is complete, the new business configuration maintenance object is displayed. The generated business object checks the `S_TABU_NAM` authorization object with the `ZLH_R_CATEGORY_HDR` CDS entity and the 03 (read)/02 (modify) activity.

To consume the business configuration maintenance object, you need to create an IAM app and then create a business catalog and a business role that you can assign to your business user. The steps are mentioned below.

## Create an IAM App

1. Right-click the package and choose **New > Other ABAP Repository Object**.
2. Search for **IAM App**, select it and choose **Next >**.
3. Create new IAM app with the following values and choose **Next >**.
    - Name: `ZLH_CATEGORY_MAINT_MBC`
    - Description: `Category maintenance using BCM Object`
    - Application Type: `Business Configuration App`
4. Select a transport request and choose **Finish**.
5. Choose **Services** and add a new service.
6. Select your service:
    - Service Type: `OData V4`.
    - Service Name: `ZLH_CATEGORY_MAINTAIN_O4`.
7. Choose **Authorizations** and add a new authorization object.
8. Search for `S_TABU_NAM` and choose **OK**.
9. Select `S_TABU_NAM`, select **ACTVT** under **Authorization 0001** to check `Change` and `Display`.
10. Select **TABLE** and add the `ZLH_R_CATEGORY_HDR` entity.
11. Save the IAM app.

## Create a Business Catalog and Assign Roles

1. In the overview section of the IAM app, choose **Create a new Business Catalog and assign the App to it**.
2. Enter a name(**ZLH_CATEGORY_MAINT_BC**) and description and choose **Next>**.
3. The wizard for creating a business catalog app assignment opens automatically. Choose **Next>**.
4. Select a transport request and choose **Finish**.
5. In the business catalog, choose **Publish Locally** to be able to test your app in the development system.
6. Assign the business catalog to the business role and maintain the restrictions. For more information, refer to [Creating Business Roles and Assigning Business Users](16_AuthorizationObject_IAM_Roles.md#creating-business-roles-and-assigning-business-users).
