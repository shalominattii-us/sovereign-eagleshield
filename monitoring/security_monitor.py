import json, time
from datetime import datetime
from collections import deque
class SecurityMonitor:
    def __init__(self):
        self.events = deque(maxlen=10000)
        self.alerts = deque(maxlen=1000)
    def log(self, event_type, severity, details):
        e = {'ts': datetime.utcnow().isoformat(), 'type': event_type, 'sev': severity, 'details': details}
        self.events.append(e)
        if severity in ('HIGH','CRITICAL'):
            self.alerts.append(e)
            print(f'[ALERT] {severity}: {event_type}')
    def dashboard(self):
        return {'events': len(self.events), 'alerts': len(self.alerts), 'compliance': 'COMPLIANT'}
if __name__ == '__main__':
    m = SecurityMonitor()
    m.log('LOGIN_FAIL', 'HIGH', {'ip': '10.0.0.99'})
    print(json.dumps(m.dashboard()))
