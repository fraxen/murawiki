<cfscript>
component accessors="true" output="false" extends="mura.cfobject" {
	property name='beanFactory';
	property name='locks';

	public any function init() {
		setLocks({});
		return THIS;
	}

	public any function cleanup() {
		// Removes all outdated locks
	}

	public any function check(required string WikiID, required string label) {
		// Check if it is locked, if it is, return info about lock
		var lockStatus = {};
		if (StructKeyExists(getLocks(), WikiID) && StructKeyExists(getLocks()[WikiID], Label) ) {
			lockStatus = getLocks[WikiID][Label];
			lockStatus.Insert('locked', true);
		} else {
			lockStatus = {locked: false};
		}
		return lockStatus;
	}

	public any function request(required string WikiID, required string label, required string UserID) {
		// Check if it is locked, if it is, return negative result
		// If it is not locked already, create a new lock
	}
	
	public void function release(required string WikiID, required string label, required string UserID) {
	}
}
</cfscript>
