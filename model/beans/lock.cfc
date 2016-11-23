<cfscript>
component accessors="true" output="false" {
	// A status message object, to be stored in the currentUser session facade
	property name='UserID';
	property name='Expiration';
	property name='ExpirationIso';

	public any function init(required string UserID, required numeric lockTime) {
		var nowDateIso = '';
		setUserID(ARGUMENTS.UserID);
		setExpiration(DateAdd('n', ARGUMENTS.lockTime, Now()));
		nowDateIso = DateConvert('local2utc', getExpiration());
		setExpirationIso(
			DateFormat(nowDateIso, 'yyyy-mm-dd') &
			'T' &
			TimeFormat(nowDateIso, 'HH:mm:ss') &
			'Z'
		);
		return THIS;
	}
}
</cfscript>
