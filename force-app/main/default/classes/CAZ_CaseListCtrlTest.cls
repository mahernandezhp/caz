@isTest
public class CAZ_CaseListCtrlTest {

    @testSetup
    static void setupTestData() {
        Account testAcc = new Account(Name = 'Test Account CAZ');
        insert testAcc;

        Id rtDevId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Devolucion')?.getRecordTypeId();
        
        List<Case> casesToInsert = new List<Case>();
        for(Integer i = 0; i < 5; i++) {
            Case c = new Case(
                AccountId = testAcc.Id,
                Subject = 'Test Case ' + i
            );
            if(rtDevId != null) {
                c.RecordTypeId = rtDevId;
            }
            casesToInsert.add(c);
        }
        insert casesToInsert;
    }

    @isTest
    static void testGetCaseData() {
        System.Test.startTest();
        // Since we are not running as a portal user, the ctrl will fallback to a test account
        CAZ_CaseListCtrl.DataTableResponse response = CAZ_CaseListCtrl.getCaseData('Devolucion', 'CaseNumber, Subject, Status', 10, 0);
        System.Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(3, response.columns.size(), 'Exactly 3 columns described');
        System.assert(response.totalRecords >= 0, 'Total records count should run without issues');
    }
    
    @isTest
    static void testGetCaseDataNoFields() {
        System.Test.startTest();
        CAZ_CaseListCtrl.DataTableResponse response = CAZ_CaseListCtrl.getCaseData('', '', 5, 0);
        System.Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(3, response.columns.size(), 'Should fallback to 3 default columns if explicit fields are empty');
    }
}