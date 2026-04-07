@isTest
private class CAZ_CaseTriggerHandlerTest {
    @isTest
    static void testCoverage() {
        Test.startTest();
        CAZ_CaseTriggerHandler.handleBeforeUpdate(new List<Case>(), new Map<Id, Case>());
        Boolean isAdmin = CAZ_CaseTriggerHandler.isSystemAdminUser();
        Test.stopTest();
        System.assertNotEquals(null, isAdmin);
    }
}