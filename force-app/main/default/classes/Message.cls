// PMD False Positive: API properties require underscores
@SuppressWarnings('PMD.FieldNamingConventions')
public class Message {

    @AuraEnabled public String id;
    @AuraEnabled public String role;
    @AuraEnabled public String run_id;
    @AuraEnabled public List<Content> content = new List<Content>();
    @AuraEnabled public Metadata metadata;
    
    // PUBLIC

    public Message() {}

    public Message(String text) {
        role = 'user';
        content = new List<Content>{ new Content(text) };
    }

    public static Message create(String threadId, Message message) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('role', message.role);
        payload.put('content', message.content[0].text.value);

        return (Message) new OpenAiApi('/threads/' +  threadId + '/messages')
                                .body(payload)
                                .post(Message.class);
    }

    public static Message modify(String threadId, Message message) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('metadata', message.metadata);

        return (Message) new OpenAiApi('/threads/' +  threadId + '/messages/' + message.id)
                                .body(payload)
                                .post(Message.class);
    }

    public static Message.Messages retrieve(String threadId, Params params) {
        return (Message.Messages) new OpenAiApi('/threads/' +  threadId + '/messages' + params.asQueryString())
                                        .get(Message.Messages.class);
    }

    // INNER

    public class Messages {
        public List<Message> data;
    }

    public class Text {
        @AuraEnabled public String value;
    }
    
    public class Content {
        @AuraEnabled public String type;
        @AuraEnabled public Text text = new Text();

        public Content(String value) {
            text.value = value;
        }
    }

    public class Metadata {
        @AuraEnabled public String isFeedbackPositive;
    }
}