trigger CAZ_AccountContactRelationTrigger on AccountContactRelation (after insert, after update, after delete) {
    CAZ_AccountContactRelationHandler.manageAccountSharing(
        Trigger.isDelete ? Trigger.old : Trigger.new,
        Trigger.isUpdate ? Trigger.oldMap : null,
        Trigger.operationType
    );
}
