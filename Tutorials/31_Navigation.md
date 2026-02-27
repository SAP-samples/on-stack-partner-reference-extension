***

# Introducing Navigation Links and Semantic Actions

## Overview

To enable seamless navigation between the **Manage Sales Orders** app, the **Loyalty Hub** app, and the **Manage Business Partner** app, we provide **semantic actions** and **launchpad navigation links**. 

These enable users to move effortlessly between apps, such as:

*   From **Manage Sales Orders → Loyalty Hub**
*   From **Sold-To Party → Loyalty Hub**
*   From **Loyalty Hub → Business Partner (Manage Business Partner app)**

This setup involves:

*   Creating **Launchpad app descriptor items**
*   Creating **IAM apps** (with external app type)
*   Adding IAM apps to the **business catalog**
*   Adding **intent-based navigation annotations** in CDS metadata extensions
*   Making the navigation available in:
    *   **Smart Links** (from the standard sales order apps)
    *   **Related Apps** section
    *   **Object page buttons** or **field actions**

These steps ensure that standard SAP sales order applications can deep‑link into the custom **Loyalty Hub** application for a smooth UX flow.

***

## Launchpad Navigation from Sold-To Party to Loyalty Hub
![9c4f997d-c1e2-4007-a63e-214ed965aef8](https://github.tools.sap/user-attachments/assets/af471afa-0469-4a14-9d90-34fee772f0f8)



### Purpose

Enable a navigation link on the **Sold-to Party smart link popover** that navigates directly into the **Loyalty Hub Membership Management** screen for the selected customer.

***

### Step 1 — Create Launchpad App Descriptor Item

Follow these steps in ABAP development tools for Eclipse (ADT):

1.  Right‑click the `ZPRA_LOYALTYHUB` package and choose **New** > **Launchpad App Descriptor Item**.

2.  Provide the following values:

| Field                   | Value                                          |
| ----------------------- | ---------------------------------------------- |
| **Name**                | `ZLH_SOLDTOPARTYTOLOYLTYHUB`                   |
| **Description**         | *Manage Loyalty Membership from Sold-To Party* |
| **SAPUI5 Component ID** | `loyaltyhub`                                   |
| **Semantic Object**     | `Customer`                                     |
| **Action**              | `maintainLoyaltyMembership`                    |

3.  Finish and activate.

This step introduces a **semantic object–action pair** that SAP Fiori uses for context-based navigation.

***

### Step 2 — Create IAM App

1.  Open **ADT > IAM > Create IAM App**.
2.  Enter the following:

| Field            | Value                          |
| ---------------- | ------------------------------ |
| **IAM App Name** | `ZLH_SOLDTOPARTY_IAM`          |
| **Description**  | *Sold-To Party to Loyalty Hub* |
| **App Type**     | **External App**               |

This IAM app represents the navigation target on SAP Fiori launchpad.

***

### Step 3 — Assign IAM App to Business Catalog

1.  Open the `ZLOYALTYHUB_BUS_CATALOG` business catalog.
2.  Navigate to the **Apps** section.
3.  Choose **Add**.
4.  Add the `ZLH_SOLDTOPARTY_IAM` IAM app.

This makes the navigation link available to end user roles that are assigned to this business catalog.

***

## Navigation from Sales Order to Loyalty Hub

You can find the smart link navigation in the **Related Apps** section.

### Overview

In addition to the sold-to party navigation, users may also want to jump to the **Loyalty Hub** app directly from the sales order itself.  
You can expose this navigation from the **Related Apps** popover.  
***
![b5d13616-e616-4d72-bd9b-7838ba54d56a](https://github.tools.sap/user-attachments/assets/1d65e70c-cc87-4ee6-a4d8-c6378e00c7ba)


### Step 1 — Create Launchpad App Descriptor Item
Follow these steps in ABAP development tools for Eclipse (ADT):
1.  Right-click `ZPRA_LOYALTYHUB` and choose **New > Launchpad App Descriptor Item**.

2.  Enter the following:

| Field                   | Value                                        |
| ----------------------- | -------------------------------------------- |
| **Name**                | `ZLH_SOTOLOYLTYHUB`                          |
| **Description**         | *Manage Loyalty Membership from Sales Order* |
| **SAPUI5 Component ID** | `loyaltyhub`                                 |
| **Semantic Object**     | `SalesOrder`                                 |
| **Action**              | `maintainLoyaltyMembership`                  |

Activate the descriptor item.

***

### Step 2 — Create IAM App

Create a second IAM app for the sales order–based navigation:

| Field            | Value                        |
| ---------------- | ---------------------------- |
| **IAM App Name** | `ZLH_SALESORDER_IAM`         |
| **Description**  | *Sales Order to Loyalty Hub* |
| **App Type**     | **External App**             |

***

### Step 3 — Assign IAM App to Business Catalog

1.  Open the same business catalog named `ZLOYALTYHUB_BUS_CATALOG`.
2.  Go to the **Apps** section.
3.  Choose **Add**.
4.  Add the `ZLH_SALESORDER_IAM` IAM app.


These navigation links allow end users to jump directly to the **Manage Loyalty Membership** app from key touchpoints in sales order processing.

***

## Navigation from Loyalty Hub to Manage Business Partner

<img width="887" alt="image" src="https://github.tools.sap/user-attachments/assets/849199ec-707a-40ae-bb39-58ef7fddf529" />


### Intent-Based Navigation Annotation

In addition to navigating **to** the **Loyalty Hub** from other apps, users may also need to navigate *out* of the **Loyalty Hub** to manage the corresponding **business partner master data**.

This is achieved through **intent-based navigation annotations** added to the **Sold-To Party** field inside the **Loyalty Hub** application.

These annotations make the **Business Partner** field behave like a smart link, offering the following option:

 type: #WITH_INTENT_BASED_NAVIGATION,
    semanticObject: 'BusinessPartner', semanticObjectAction: 'manage',
    semanticObjectBinding: [{element: 'BusinessPartner',localElement: 'SoldToParty'  }]}]

> **"Manage Business Partner"**

This takes the user to the standard SAP application for maintaining customer master data.

***



