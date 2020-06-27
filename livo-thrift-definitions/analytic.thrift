namespace java tr.com.eno.aeon.thrift.analytics

include "shared.thrift"

typedef shared.AuthenticationToken AuthenticationToken

struct Parameters {

  1: optional map<string, string> stringParameters;
  2: optional map<string, double> doubleParameters;
  3: optional map<string, bool> boolParameters;
  4: optional map<string, i64> numberParameters;
}

struct Event {

  1: required string id;
  2: required string name;
  3: optional Parameters parameters;
  4: optional i64 startTime;
  5: optional i64 endTime;
}

struct Error {

  1: required i64 time;
  2: required string message;
  3: optional Parameters parameters;
}

service AnalyticsService {

  bool isOptedIn(1: AuthenticationToken token);
  void optOut(1: AuthenticationToken token);
  void optIn(1: AuthenticationToken token);

  void logEvent(1: AuthenticationToken token, 2: Event event);
  void logError(1: AuthenticationToken token, 2: Error error);
}
