# Import and Run the Application

## Overview

This tutorial provides a step-by-step guide for importing and running the **Loyalty Hub** app in your SAP S/4HANA Cloud Public Edition system. This solution is designed as a [**multi-off delivery**](https://help.sap.com/docs/SAP_S4HANA_CLOUD/6aa39f1ac05441e5a23f484f31e477e7/dbeaf0f2a7ea4096be1a297458079547.html). Follow these steps to import the solution into your SAP S/4HANA Cloud Public Edition system.

## Importing the Loyalty Hub

1. [**Prerequisites on Target Landscapes:**](https://help.sap.com/docs/SAP_S4HANA_CLOUD/6aa39f1ac05441e5a23f484f31e477e7/a992a1c115f24e0fab1e9a67b15b9aea.html) 
   - Obtain the repository URL to pull the extension objects into your target repository.

2. [**Providing Credentials on Target Landscapes**](https://help.sap.com/docs/SAP_S4HANA_CLOUD/6aa39f1ac05441e5a23f484f31e477e7/32389560af454b68a2d9cfe73f8457d7.html)
   - Provide your credentials for the Git provider in the gCTS app.

3. [**Connecting to the Repository on Target Landscapes:**](https://help.sap.com/docs/SAP_S4HANA_CLOUD/6aa39f1ac05441e5a23f484f31e477e7/9f329770b7c04b03af44de6cb350c71c.html)
   - Create the repository connection in the system (development).
   - Clone the repository into your SAP S/4HANA Cloud Public Edition system.

## Running the Loyalty Hub

**Prerequisites**: You've created business partners that can be used as a sold-to party when you create sales orders in your SAP S/4HANA Cloud Public Edition system. A sales order can be created in the system with the **Incompletion Status** set to `Complete`.

1. Go through the [README](../README.md) file and understand the personas involved in the **Loyalty Hub** app.
2. Kindly verify that all objects are activated and business catalogs have been successfully published.
3. [Create business roles and assign the business users to the role](./16_AuthorizationObject_IAM_Roles.md#creating-business-roles-and-assigning-business-users).
4. Create a customizing transport to save the configurations.
   - Log on to SAP Fiori launchpad as **Administrator** and open the **Export Customizing Transports** app.
   - Choose **Create**. Provide the **Description** and set **Technical Type** as `Customizing Request` and choose **Create**.
5. To use the **Loyalty Hub** application, you must maintain a number range interval.
   - Use the **Manage Number Range Intervals** app to maintain number range interval.
   - For number range object list and other details, refer to [Number Range Solution](./41_NumberRange.md).
6. You can use the [Custom Business Configurations App](https://help.sap.com/docs/btp/sap-business-technology-platform/custom-business-configurations-app?version=Cloud) to configure the categories used in Loyalty Hub Membership.
7. Open the **Custom Business Configurations** app.
8. Choose **Maintain Loyalty Hub Categories**.
9. Create a category with the following details:
   - **Category Name**: Name of the category
   - **Enabled**: Yes (to enable the category for use)
   - **Default**: Yes (for the category to be considered by default during membership creation)
   - **Minimum points**: Minimum points to be accumulated by the user to be assigned to the category (0 for default category).
   - **Conversion value**: The multiplier applied to the sales order net price for points calculation
      - Example: If the net price of the sales order is 200 and the conversion value maintained for the assigned category is 0.1, the points allocation is 200 * 0.1 = 20.
10. Save the entries and lock it in the customizing transport you've created.




    
