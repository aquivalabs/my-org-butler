// PMD False Positives: Agentforce requires Global
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class NotifyUser {

    @InvocableMethod(label='MyOrgButler: Notify User' description='Sends an in-org notification to specific users, optionally linking to a record')
    global static List<Output> execute(List<Input> inputs) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('My Org Butler says:');
        notification.setBody(inputs[0].body);
        notification.setNotificationTypeId([SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'InOrgNotifications'].Id);
        notification.setTargetId(inputs[0].targetId);
        Set<String> userIds = String.isBlank(inputs[0].recipientIds)
            ? new Set<String>{ UserInfo.getUserId() }
            : new Set<String>(inputs[0].recipientIds.split(','));
        notification.send(userIds);

        List<Output> result = new List<Output>{ new Output() };

        return result;
    }


    // INNER

    global class Input {
        @InvocableVariable(label='Body' description='Conversational message from the agent. Write like a friendly assistant.' required=true)
        global String body;

        @InvocableVariable(label='Target Record Id' description='Salesforce Id of the record to link to. Use 000000000000000AAA if none' required=true)
        global String targetId;

        @InvocableVariable(label='Recipient User Ids' description='Comma-separated Salesforce User Ids to send the notification to' required=false)
        global String recipientIds;
    }


    global class Output {
        @InvocableVariable(label='Status' description='Confirmation that the notification was sent')
        global String status = 'sent';
    }
}
