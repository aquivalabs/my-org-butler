// PMD False Positive: API properties require underscores
@SuppressWarnings('PMD.FieldNamingConventions')
public class Thread {
    
    public String id;

    public Thread id(String value) {
        id = value;
        return this;
    }

    public static Thread create() {
        Map<String, Object> payload = new Map<String, Object>();

        return (Thread) new OpenAiApi('/threads').body(payload).post(Thread.class);
    }

    public static Thread retrieve(String threadId) {
        return (Thread) new OpenAiApi('/threads/' + threadId).get(Thread.class);
    }

    public static void remove(String threadId) {
        new OpenAiApi('/threads/' + threadId).remove();
    }
}