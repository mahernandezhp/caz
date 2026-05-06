public with sharing class CAZ_CkDistCtrl {
    public PageReference go() {
        String accountId = getAccountId();
        String target = '/lightning/o/CAZ_Checklist_Monitoreo__c/new?recordTypeId=012WD000001XukPYAS';

        if (String.isNotBlank(accountId)) {
            target += '&defaultFieldValues=' +
                EncodingUtil.urlEncode('CAZ_Cuenta__c=' + accountId, 'UTF-8');
        }

        PageReference nextPage = new PageReference(target);
        nextPage.setRedirect(true);
        return nextPage;
    }

    private String getAccountId() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        List<String> keys = new List<String>{ 'id', 'recordId', 'recordIds', 'ids', 'sfid', 'whatId', 'parentId' };

        for (String key : keys) {
            String value = params.get(key);
            if (String.isNotBlank(value)) {
                return value.split(',')[0];
            }
        }

        return null;
    }
}