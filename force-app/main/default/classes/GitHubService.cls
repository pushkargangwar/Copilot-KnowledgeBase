public class GitHubService {
    public static String fetchRawFile(String rawUrl) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(rawUrl);
        req.setMethod('GET');
        // If private repository, set Authorization header:
        // req.setHeader('Authorization','token ' + 'YOUR_GITHUB_PERSONAL_ACCESS_TOKEN');
        HttpResponse resp = http.send(req);
        if (resp.getStatusCode() == 200) {
            return resp.getBody();
        } else {
            System.debug('GitHub fetch failed: ' + resp.getStatus() + ' ' + resp.getBody());
            return null;
        }
    }
}