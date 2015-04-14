import requests, json, pprint, sys
from requests.auth import HTTPBasicAuth

class SonarStats:
    @property
    def url(self):
        return "http://127.0.0.1:9000/sonar/api/resources"

    @property
    def coverage_url_params(self):
        return {'format': 'json', 'metrics': 'coverage'}

    @property
    def violations_url_params(self):
        return {'format': 'json', 'metrics': 'major_violations,critical_violations,blocker_violations'}

    def _add_violations(self, project):
        total = 0
        for measure in project['msr']:
            total = total + measure['val']

        return total

    def get_coverage_percentage(self, project_key):
        r = requests.get(self.url, params=self.coverage_url_params, auth=HTTPBasicAuth('jenkins', 'JenkinsPass'))
        data = json.loads(r.content.decode())
        project = self._find_project(data, project_key)
        return self._get_coverage_percentage(project)

    def get_violation_count(self, project_key):
        r = requests.get(self.url, params=self.violations_url_params, auth=HTTPBasicAuth('jenkins', 'JenkinsPass'))
        data = json.loads(r.content.decode())
        project = self._find_project(data, project_key)
        return self._add_violations(project)

    def _get_coverage_percentage(self, project):
        if project is None:
            return 0.0

        for measure in project['msr']:
            if measure['key'] == 'coverage':
                return measure['val']

        return 0.0

    def _find_project(self, data, project_key):
        for x in data:
            if x['key'] == project_key:
                return x

        return None


key='dk:godaddy-cijtemplate'
sonar = SonarStats()

coverage = sonar.get_coverage_percentage(key)
if coverage < 90.0:
    print('Failed code coverage requirements. Code coverage below 90% ({0}%)'.format(coverage))
    sys.exit(1)

violations = sonar.get_violation_count(key)
if violations != 0:
    print('Violation count above zero for major, critical, and blocker ({0})'.format(violations))
    sys.exit(1)


sys.exit(0)
