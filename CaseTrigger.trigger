trigger CaseTrigger on Case (after insert, after update, after delete, after undelete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            CaseTriggerHandler.updateAccountCaseCounts(Trigger.new, Trigger.oldMap);
        }

        when AFTER_UPDATE {
            CaseTriggerHandler.updateAccountCaseCounts(Trigger.new, Trigger.oldMap);
        }

        when AFTER_DELETE {
            CaseTriggerHandler.updateAccountCaseCounts(Trigger.old, null);
        }

        when AFTER_UNDELETE {
            CaseTriggerHandler.updateAccountCaseCounts(Trigger.new, null);
        }
    }
}