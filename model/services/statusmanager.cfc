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
