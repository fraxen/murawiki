<cfscript>
component accessors="true" output="false" extends="mura.cfobject" {
	property name='beanFactory';
	property name='locks';
	property name='lockTime'; //minutes of lock time

	public any function init() {
		setLocks({});
		return THIS;
	}

	public void function cleanup() {
		for (var WikiId in VARIABLES.Locks) {
			for (var label in VARIABLES.locks[WikiId]) {
				if (VARIABLES.locks[WikiId][Label].getExpiration() < Now()) {
					StructDelete(VARIABLES.locks[WikiId], Label);
				}
			}
		}
	}

	private array function getLocksByWikiId(required string WikiId) {
		var outLocks = [];
		if (StructKeyExists(VARIABLES.locks, ARGUMENTS.WikiID)) {
			for (var label in VARIABLES.locks[ARGUMENTS.WikiID]) {
				if (VARIABLES.locks[ARGUMENTS.WikiId][label].getExpiration() < Now()) {
					ArrayAppend(outLocks, VARIABLES.locks[ARGUMENTS.WikiId][label]);
				}
			}
		}
		return outLocks;
	}

	private object function getLocksByWikiIdLabel(required string WikiId, required string Label) {
		if (StructKeyExists(VARIABLES.locks, ARGUMENTS.WikiID) && StructKeyExists(VARIABLES.locks[ARGUMENTS.WikiID], ARGUMENTS.Label)) {
			return VARIABLES.locks[ARGUMENTS.WikiID][ARGUMENTS.Label];
		}
		return {};
	}

	public struct function check(required string WikiID, required string label) {
		// Check if it is locked, if it is, return info about lock
		var lockStatus = {};
		var thisLock = getLocksByWikiIdLabel(ARGUMENTS.WikiID, ARGUMENTS.Label);
		if (isObject(thisLock)) {
			lockStatus.lock = thisLock;
			lockStatus.locked = true;
		} else {
			lockStatus.locked = false;
		}
		return lockStatus;
	}

	public any function request(required string WikiID, required string label, required string UserID) {
		var lockStatus = check(ARGUMENTS.WikiID, ARGUMENTS.Label);
		if (lockStatus.locked && lockStatus.lock.getUserID() != ARGUMENTS.UserID) {
			lockStatus.locked = false;
			return lockStatus;
		}
		lockStatus.lock = getBeanFactory().getBean('lock', {UserID: ARGUMENTS.UserID, lockTime: getLockTime()});
		lockStatus.locked = true;
		if (!StructKeyExists(VARIABLES.locks, ARGUMENTS.WikiID)) {
			VARIABLES.locks[ARGUMENTS.WikiID] = {};
		}
		VARIABLES.locks[ARGUMENTS.WikiID][ARGUMENTS.Label] = lockStatus.lock;
		return lockStatus;
	}
	
	public void function release(required string WikiID, required string label, required string UserID) {
		if (!StructKeyExists(VARIABLES.locks, ARGUMENTS.WikiID)) {
			VARIABLES.locks[ARGUMENTS.WikiID] = {};
		}
		if (StructKeyExists(VARIABLES.locks[ARGUMENTS.WikiId], ARGUMENTS.Label) && VARIABLES.locks[ARGUMENTS.WikiId][ARGUMENTS.Label].getUserID() == ARGUMENTS.UserID) {
			StructDelete(VARIABLES.locks[ARGUMENTS.WikiId], ARGUMENTS.Label);
		}
	}
}
</cfscript>
