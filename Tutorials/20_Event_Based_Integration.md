# Local RAP Event Consumption – Sales Order Integration with Loyalty Hub
## Overview

This guide explains how to build a **Local RAP Event Consumer** that reacts to **Sales Order Created** and **Sales Order Updated** events from the `I_SalesOrderTP` business object interface and automatically generates **Loyalty Transactions** in the **Loyalty Hub** app.

Local RAP events allow your applications to respond to BO instance changes **within the same ABAP system**, without SAP Event Mesh. These events execute **after the database commit** of the triggering business object.

This integration ensures:

*   Loyalty points/transactions are created as soon as sales orders are completed.
*   Transactions are generated only for **customers with active memberships**.
*   Duplicate loyalty postings are avoided through built‑in idempotency checks.

***

## 1. Create the Global Event Handler Class

The global event handler registers your application as a **consumer** of sales order events.

### What this Component Does

*   It declares that the class listens to events of `I_SalesOrderTP`.
*   It provides the event routing structure for RAP.
*   It delegates the actual logic to a local handler inside the class include.

### Steps

1.  In ADT, right‑click the **ZPRA_LOYALTYHUB** package and choose **New** → **Other ABAP Repository Object**.
2.  Select **ABAP Class**.
3.  Enter the following:
    *   **Class Name:** `ZLH_SALESORDER_INTEGRATION`
    *   **Description:** *Integration with Manage Sales Orders App*
4.  Assign a transport request and activate.

📌 For more information, refer to global handler class [**ZLH_SALESORDER_INTEGRATION**](../objects/CLAS/ZLH_SALESORDER_INTEGRATION/CINC%20ZLH_SALESORDER_INTEGRATION%3D%3D%3D%3DCCIMP.abap).

***

## 2. Implement the Local RAP Event Consumer

This local class (inside the class include) contains the **actual event handler methods**, such as:

*   `on_created` → triggered after sales order creation is committed
*   `on_updated` → triggered after sales order changes are committed

### What this Component Does

*   It provides callback methods that RAP calls when a sales order is created or changed.
*   It reads the keys of affected sales orders from the event payload.
*   It retrieves detailed sales order data required for loyalty logic.
*   It delegates further processing to the handler implementation.

### High-Level Steps

1.  on the **Local Types** tab of the same class, create a new local class inheriting from  
    `CL_ABAP_BEHAVIOR_EVENT_HANDLER`.
2.  Define handler methods for:
    *   SalesOrder **created**
    *   SalesOrder **changed**
3.  Activate the class.

📌 For more information, refer to the local handler class **LHE_EVENT** inside the **ZLH_SALESORDER_INTEGRATION** class.

***

## 3. Event Handling Logic (Creation and Update)

The event handling logic defines **how Loyalty Transactions are created** when a sales order event is received.

Below is a conceptual explanation of what the implementation performs.

***

### 3.1 Read Sales Order Details

After receiving an event, the handler:

*   Reads the full sales order records associated with the event keys
*   Extracts fields such as:
    *   **SoldToParty**
    *   **TotalNetAmount**
    *   **Currency**
    *   **Header Completion Status**

📌 This ensures that processing is based on the latest committed sales order state.

***

### 3.2 Validate Eligibility

The logic ensures only valid transactions are processed.

**Conditions that are checked include:**

#### ✔ Order must be complete

Only orders with a clear incompletion log are eligible.

#### ✔ Sold-to party must be an active loyalty member

The handler verifies that:

*   A membership exists
*   The membership has not expired
*   The membership status is active

#### ✔ Transaction must not already exist

To prevent duplicates, the implementation checks if a loyalty transaction for the same sales order already exists.

If yes, the event is ignored.

***

### 3.3 Prepare Loyalty Transaction Data

If the order is eligible, the handler prepares the data needed to create a new loyalty transaction.

This includes information such as:

*   Activity type (fpr example, a purchase)
*   Reference sales order ID
*   Transaction amount
*   Currency
*   Parent business partner key

📌 The data is staged in an internal table that represents child entries of the business partner entity.

***

### 3.4 Create Transactions Using RAP EML

Once all records are prepared, the handler uses **MODIFY ENTITIES** to create child entries under the business partner.

This ensures that:

*   RAP handles referential integrity
*   The save sequence is respected
*   Draft behavior (if applicable) is handled correctly
*   Error handling is automatically captured

📌 For more information, refer to loyalty transaction creation logic inside `LHE_EVENT → on_created` and `LHE_EVENT → on_updated`.

***

## 4. Testing the Integration

To validate that Local RAP Events are working correctly, follow these steps:

1. Open the **Manage Sales Orders** app.
2. Create or update a sales order.
3. Ensure that the sales order is complete. That is: no missing fields, no incompletion log issues.
4. Ensure that the sold-to party is a valid loyalty member. That is: The membership is active and not expired.
5. Save the sales order. This triggers the local RAP event.
6. Navigate to **Loyalty Hub** app.
7. Open the **Transactions** section for the business partner.
8. Validate the following:

*   A new transaction is created for eligible sales orders.
*   No duplicates appear for repeated changes.
*   No transaction is created for incomplete or invalid orders.

***

For more information, see [Business Event Consumption](https://help.sap.com/docs/abap-cloud/abap-rap/business-event-consumption?locale=en-US) on SAP Help Portal.

