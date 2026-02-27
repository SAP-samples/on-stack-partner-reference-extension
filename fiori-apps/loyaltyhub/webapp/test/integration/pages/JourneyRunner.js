sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"loyaltyhub/test/integration/pages/BusinessPartnerList",
	"loyaltyhub/test/integration/pages/BusinessPartnerObjectPage"
], function (JourneyRunner, BusinessPartnerList, BusinessPartnerObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('loyaltyhub') + '/test/flp.html#app-preview',
        pages: {
			onTheBusinessPartnerList: BusinessPartnerList,
			onTheBusinessPartnerObjectPage: BusinessPartnerObjectPage
        },
        async: true
    });

    return runner;
});

