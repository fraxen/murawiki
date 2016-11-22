<cfscript>
component accessors="true" output="false" extends="mura.cfobject" {
	property name='beanFactory';

	private any function getCurrentUser() {
		return application.serviceFactory.getBean('muraScope').init('default').currentUser();
	}

	public any function addStatus(required string WikiId, required any statusBean) {
		var cUser = getCurrentUser();
		var queue = cUser.getMuraWikiStatusQueue();
		if (!IsStruct(queue)) {
			queue = {};
		}
		if (!StructKeyExists(queue, ARGUMENTS.WikiId)) {
			queue[ARGUMENTS.WikiId] = [];
		}

		// If there are dupes, delete the dupe
		// Also some special cases...
		for (var i=ArrayLen(queue[ARGUMENTS.WikiId]); i > 0; i--) {
			if (
				(
					// it is a dupe - delete it
					queue[ARGUMENTS.WikiId][i].getLabel() == ARGUMENTS.statusBean.getLabel()
					&&
					queue[ARGUMENTS.WikiId][i].getKey() == ARGUMENTS.statusBean.getKey()
				) || (
					// do not display lockrelease if there is a new lock message
					queue[ARGUMENTS.WikiId][i].getLabel() == ARGUMENTS.statusBean.getLabel()
					&&
					queue[ARGUMENTS.WikiId][i].getKey() == 'lockrelease'
					&&
					ARGUMENTS.statusBean.getKey() == 'locked'
				)
			) {
				ArrayDeleteAt(queue[ARGUMENTS.WikiId], i);
				continue;
			}
			if (
				queue[ARGUMENTS.WikiId][i].getLabel() == ARGUMENTS.statusBean.getLabel()
				&&
				queue[ARGUMENTS.WikiId][i].getKey() == 'lockfailop'
				&&
				ARGUMENTS.statusBean.getKey() == 'lockinfo'
			) {
				// No need to display lockinfo if there is a lockfailop in the queue
				return THIS;
			}
		}

		ArrayAppend(queue[ARGUMENTS.WikiId], ARGUMENTS.statusBean);
		cUser.setMuraWikiStatusQueue(queue);
		return THIS;
	}

	public struct function getStatusAll() {
		var cUser = getCurrentUser();
		if (!IsStruct(cUser.getMuraWikiStatusQueue())) {
			return {};
		}
		return cUser.getMuraWikiStatusQueue();
	}

	public array function getStatusPop(required string WikiId) {
		var queue = getStatusAll();
		var outQueue = [];
		if (!StructKeyExists(queue, ARGUMENTS.WikiId)) {
			return [];
		} else {
			outQueue = Duplicate(queue[ARGUMENTS.WikiId]);
			queue[ARGUMENTS.WikiId] = [];
			getCurrentUser().setMuraWikiStatusQueue(queue);
			return outQueue;
		}
		
	}

}
</cfscript>
