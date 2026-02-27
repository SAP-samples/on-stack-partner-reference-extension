sap.ui.define([
    "sap/ui/core/BusyIndicator",
    "sap/ui/core/format/DateFormat",
    "sap/ui/comp/valuehelpdialog/ValueHelpDialog",
    "sap/m/Table",
    "sap/m/Column",
    "sap/m/Label",
    "sap/m/ColumnListItem",
    "sap/m/Text",
    "sap/ui/model/json/JSONModel",
], function(
    BusyIndicator,
    DateFormat,
    ValueHelpDialog,
    Table,
    Column,
    Label,
    ColumnListItem,
    Text,
    JSONModel
    ) {
    "use strict";
    var that = {
        oExtensionAPI: {},
        sCustomerReturn: "",
        oResourceBundle: {},
        oExtensionAPI: {},

        fnCreateCategoryDialog: function(oEvent) {
            var oObjectDetails = this.getBindingContext().getObject();
            if (oObjectDetails.MembershipEndDate !== "9999-12-31") {
                sap.m.MessageBox.error("Category cannot be created for Inactive Membership.");
                return;
            }
            if (!this._createDialogFragment) {
                this._createDialogFragment = this.loadFragment({
                name: "loyaltyhub.ext.View.CreateCategoryDialog",
                controller: this,
                });
            };
            this._createDialogFragment.then(function (oDialog) {
                this.oDialogCreate = oDialog;
                sap.ui.core.Element.getElementById("Categoryidvalue").setValue("");
                sap.ui.core.Element.getElementById("Statusidvalue").setValue("Active");
                sap.ui.core.Element.getElementById("Categoryidvalue").setValueState("None");
                sap.ui.core.Element.getElementById("Statusidvalue").setValueState("None");
                var oDialogModel = new JSONModel({
                    StartDate: new Date(),
                    EndDate: new Date(Date.UTC(9999, 11, 31, 10, 0, 0))
                });
                this.oDialogCreate.setModel(oDialogModel, "dialog");
                this.oDialogCreate.open();
            }.bind(this));
        },

        onInputChange: function(oEvent) {
            oEvent.getSource().setValueState("None");
        },

        onBlockTyping: function(oEvent) {
            var oInput = oEvent.getSource();

            // Clear manually typed input
            oInput.setValue("");

            // Optional UX hint
            oInput.setValueState("Information");
            oInput.setValueStateText("Please use value help");
            oEvent.preventDefault();
        },

        fnActionCreateCategory: function(oEvent){

            var bValid = true;

            var oCategoryInput = sap.ui.core.Element.getElementById("Categoryidvalue");

            // Category
            if (!oCategoryInput.getValue()) {
                oCategoryInput.setValueState("Error");
                oCategoryInput.setValueStateText("Category is required");
                bValid = false;
            } else {
                oCategoryInput.setValueState("None");
            }

            if (!bValid) {
                return; // Stop Create
            }
            var oDateFormat = DateFormat.getDateInstance({ pattern: "yyyy-MM-dd" });
            var aSelectedContexts = [];
            aSelectedContexts.push(oEvent.getSource().getBindingContext());
            var sActioncreatecategory= "com.sap.gateway.srvd.zloyaltyhub_manage_sd.v0001.createCategory";
            BusyIndicator.show();
            var oObjectDetails = this.getBindingContext().getObject();
            var context = oEvent.getSource().getBindingContext();
            var oAction = this.getModel().bindContext(
                sActioncreatecategory + "(...)", context
            );
            oAction.setParameter("BusinessPartner",oObjectDetails.SoldToParty);
            oAction.setParameter("membershipid",oObjectDetails.MemberShipID);
            oAction.setParameter("Categoryid",sap.ui.core.Element.getElementById("Categoryidvalue").getValue());
            oAction.setParameter("Status","A");
            var ostartdate = sap.ui.core.Element.getElementById("Startdatevalue").getDateValue();
            var sstartdate = oDateFormat.format(ostartdate);
            oAction.setParameter("Startdate",sstartdate);
            var oenddate = sap.ui.core.Element.getElementById("Enddatevalue").getDateValue();
            var senddate = oDateFormat.format(oenddate);
            oAction.setParameter("Enddate",senddate);
            oAction.execute().then(
                function (oSuccess) {
                    BusyIndicator.hide();
                    this.oDialogCreate.close();
                    this.getBindingContext().refresh();
                }.bind(this),
                function (oError) {
                    BusyIndicator.hide();
                    if (oError && oError.error && oError.error.message) {
                        var sMessage = oError.error.message;
                    }
                    sap.m.MessageBox.error(sMessage);
                }
            )
        },
        formatODataDate:function(oDate){
            var oDateFormat = DateFormat.getDateInstance({ pattern: "yyyy-MM-dd" });
            return oDateFormat.format(oDate);
        },
        onCancel: function () {
            this.oDialogCreate.close();
        },
        onDiscard: function () {
            this.oDialogCreate.close();
        },
        onValueHelpRequested: function (oEvent) {
            this._vhInput = oEvent.getSource();
            if (!this.oValueHelpDialog) {
                this.oValueHelpDialog = new ValueHelpDialog({
                    title: "Category",
                    supportRanges: false, // Disable range selection
                    supportMultiselect: false, // Allow single selection
                    key: "Categoryid",
                    contentHeight: "200px", // Set the height of the popup
                    ok: (oOkEvent) => {
                        const aTokens = oOkEvent.getParameter("tokens") || [];
                        const oInput = this._vhInput; // use the captured input
                        if (oInput && aTokens.length) {
                            oInput.setValue(aTokens[0].getKey());
                        }
                        this.oValueHelpDialog.close();
                    },
                    cancel: function () {
                        this.oValueHelpDialog.close();
                    }.bind(this)
                });
                var oTable = new Table({
                    mode: "SingleSelectMaster",
                    columns: [
                        new Column({ header: new Label({ text: "Category ID" }) }),
                        new Column({ header: new Label({ text: "Name" }) }),
                        new Column({ header: new Label({ text: "Enabled" }) }),
                        new Column({ header: new Label({ text: "Default"}) })
                    ]
                });
                var oTemplate = new ColumnListItem({ 
                    cells:[
                        new Text({ text: "{Categoryid}" }),
                        new Text({ text: "{Categoryname}" }),
                        new Text({ text: "{Isenabled}" }),
                        new Text({ text: "{Isdefault}" })
                    ]
                });
                var oModel = this.getModel(); // RAP OData V4 model
                oTable.setModel(oModel);
                var sPath = "/CategoryIdVh";
                oTable.bindItems({ 
                    path: sPath,
                    Parameters: { $select: "Categoryid,Categoryname,Isenabled,Isdefault" },
                    template: oTemplate,
                    templateShareable: false
                });
                this.oValueHelpDialog.setModel(oModel);
                this.oValueHelpDialog.setTable(oTable);
            }
            if (this.oValueHelpDialog) {
                this.oValueHelpDialog.setTokens([]);
                const oTableClear = this.oValueHelpDialog.getTable();
                if (oTableClear) {
                    oTableClear.removeSelections();
                }
            }
            this.oValueHelpDialog.open();
        },
    };
    return that;
});