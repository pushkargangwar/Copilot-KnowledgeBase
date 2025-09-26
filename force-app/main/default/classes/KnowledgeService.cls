// Minimal Knowledge upsert: adapt field names / article type to your org
public class KnowledgeService {
    public static void upsertKnowledgeArticle(String title, String bodyHtml, String sourcePath) {
        // NOTE: Replace 'Knowledge__kav' with your article type API name if needed
        // For example, if you created an ArticleType named 'Doc' the object will be 'Doc__kav'
        String articleObjApi = 'Knowledge__kav';

        // Build a map of fields. Must include Title and other required fields (RecordTypeId maybe)
        Map<String, Object> fields = new Map<String, Object>();
        fields.put('Title', title);
        fields.put('Summary', title);
        fields.put('UrlName', title.toLowerCase().replace(' ','-'));
        // principal body field name differs by article type; common field: 'ArticleBody' or 'RichText__c' (verify in your org)
        fields.put('ArticleBody', bodyHtml);
        // you can add a custom field to link back to source path
        fields.put('Source_Path__c', sourcePath);

        // Upsert - we attempt to find an existing article by Source_Path__c (requires a custom External Id field)
        try {
            // Upsert via REST SObject API from Apex: use sObject dynamic construction
            SObject s = (SObject) Type.forName('Schema', articleObjApi).newInstance();
            for (String k : fields.keySet()) {
                s.put(k, fields.get(k));
            }
            // If you have an external id field, use Database.upsert(s, 'External_Id__c'); otherwise use insert
            insert s;
        } catch (Exception ex) {
            System.debug('Knowledge upsert error: ' + ex);
        }
    }
}