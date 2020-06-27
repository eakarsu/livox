namespace java tr.com.eno.aeon.thrift.dataobjects

enum DataType {

	BOOLEAN,
	NUMERIC,
	TEXT,
	DATE,
	COMPLEX,
	// Are these needed?
	JSON,
	XML;
}

struct DataObject {

	1: required DataType type;
	2: optional map<string, DataObject> properties;
	3: optional string value;
}
