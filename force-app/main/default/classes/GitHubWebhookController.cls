@RestResource(urlMapping='/GitHubWebhook/*')
global with sharing class GitHubWebhookController {
    
    // Shared secret from GitHub webhook settings
    // Store securely (e.g., Custom Metadata or Named Credential)
    private static final String GITHUB_SECRET = 'REPLACE_WITH_YOUR_SECRET';

    @HttpPost
    global static void receive() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // 1) Validate signature
            String sigHeader = req.headers.get('X-Hub-Signature-256');
            if (String.isBlank(sigHeader) || !verifySignature(sigHeader, req.requestBody)) {
                res.statusCode = 401;
                res.responseBody = Blob.valueOf('Invalid signature');
                return;
            }

            // 2) Parse payload
            String body = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(body);

            // 3) Extract commits
            List<Map<String, Object>> commits = (List<Map<String, Object>>) payload.get('commits');
            if (commits == null || commits.isEmpty()) {
                res.statusCode = 200;
                res.responseBody = Blob.valueOf('No commits to process');
                return;
            }

            // 4) Collect files to process
            Set<String> filesToProcess = new Set<String>();
            for (Map<String, Object> com : commits) {
                List<String> added = (List<String>) com.get('added');
                if (added != null) {
                    filesToProcess.addAll(added);
                }

                List<String> modified = (List<String>) com.get('modified');
                if (modified != null) {
                    filesToProcess.addAll(modified);
                }

                // Optional: handle removed files
                // List<String> removed = (List<String>) commit.get('removed');
            }

            // 5) Process each file
            for (String path : filesToProcess) {
                try {
                    processFile(path, payload);
                } catch (Exception exFile) {
                    System.debug('Error processing file ' + path + ' : ' + exFile.getMessage());
                }
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('OK');

        } catch (Exception ex) {
            System.debug('GitHub Webhook Error: ' + ex.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Internal error');
        }
    }

    // 👉 Process a single file
    private static void processFile(String path, Map<String, Object> payload) {
        Map<String, Object> repo = (Map<String, Object>) payload.get('repository');

        String owner = null;
        if (repo != null && repo.containsKey('owner')) {
            Map<String, Object> ownerMap = (Map<String, Object>) repo.get('owner');
            owner = (String) ownerMap.get('name');
            if (String.isBlank(owner)) {
                owner = (String) ownerMap.get('login');
            }
        }

        String repoName = repo != null ? (String) repo.get('name') : null;
        String ref = (String) payload.get('ref'); // e.g. refs/heads/main
        String branch = (ref != null && ref.startsWith('refs/heads/'))
                        ? ref.replace('refs/heads/', '')
                        : 'main';

        if (String.isBlank(owner) || String.isBlank(repoName)) {
            System.debug('⚠️ Skipping file ' + path + ' due to missing repo/owner info.');
            return;
        }

        // Build raw GitHub URL
        String rawUrl = 'https://raw.githubusercontent.com/' + owner + '/' + repoName + '/' + branch + '/'
                        + EncodingUtil.urlEncode(path, 'UTF-8');

        String content = GitHubService.fetchRawFile(rawUrl);
        if (String.isBlank(content)) {
            System.debug('⚠️ No content fetched for ' + path);
            return;
        }

        // Convert filename -> title
        String title = path.substring(path.lastIndexOf('/') + 1)
                         .replace('.md', '')
                         .replace('.markdown', '')
                         .replace('-', ' ');

        // Upsert into Knowledge (custom service call)
        KnowledgeService.upsertKnowledgeArticle(title, content, path);
    }

    // 👉 Validate GitHub webhook signature
    private static Boolean verifySignature(String header, Blob body) {
        // Header looks like: "sha256=..."
        if (String.isBlank(header) || !header.startsWith('sha256=')) {
            return false;
        }

        String sig = header.substringAfter('sha256=');
        Blob key = Blob.valueOf(GITHUB_SECRET);
        Blob mac = Crypto.generateMac('HmacSHA256', body, key);
        String expected = EncodingUtil.convertToHex(mac);

        return expected.equalsIgnoreCase(sig);
    }
}