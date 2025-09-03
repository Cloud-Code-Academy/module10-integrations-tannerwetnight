/*
 * DummyJSONCallout Class Description:
 * 
 * This class, DummyJSONCallout, facilitates HTTP callouts to an external system (presumably 'DummyJsonUser' in this context) 
 * to either fetch or send user information based on a given identifier. The class supports both GET (to fetch data) 
 * and POST (to send data) operations.
 * 
 * Overview of HTTP Callouts:
 * 
 * HTTP callouts are a way for Salesforce to communicate with external systems using HTTP protocols. Through HTTP callouts, 
 * you can invoke external web services, collect data from them, or send data for further processing. Apex provides 
 * classes that enable you to both send and receive HTTP data. The primary classes for this are `HttpRequest`, which 
 * represents the request you're sending, and `HttpResponse`, which represents the response you receive.
 * 
 * Best Practices:
 * 1. Handle Exceptions: Always handle exceptions that might be thrown, to ensure your code doesn't break unexpectedly.
 * 2. Named Credentials: Use Named Credentials to store endpoint URLs and authentication details securely.
 * 3. Test Callouts: Use mock classes and interfaces to test HTTP callouts without making actual callouts.
 * 
 * For more detailed information on HTTP callouts in Apex, refer to the official Salesforce documentation: 
 * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_restful_http_httprequest.htm
 */

public with sharing class DummyJSONCallout {

	/* 
	 * Question 1
     * Fetches user information from an external system https://dummyjson.com/user/{id} ('DummyJsonUser') based on the provided dummy user ID. 
     * If the callout is successful and returns an HTTP status of 200, the method will update a contact based on the DummyJSON_Id__c with the data returned from the external system.
	 * Use the createContactFromJson method to parse the JSON response and create a Salesforce Contact object.
     * Documentation: https://dummyjson.com/docs/users
	 * This callout method should work in triggers
	 * 
     * @param dummyUserId The ID of the user in the external system to fetch data for.
     */

	
	public static void getDummyJSONUserFromId(String dummyUserId) {
		// Create HTTP request to send.
		
		HttpRequest request = new HttpRequest();
		// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
		request.setEndpoint('callout:DummyJSON' + '/user/' + dummyUserId);
		// Set the HTTP method to GET.
		request.setMethod('GET');
		// Send the HTTP request and get the response.
		HttpResponse response = new Http().send(request);
		// If the HTTP response code is successful, parse the JSON response and update the contact.
		if (response.getStatusCode() == 200){
			String responsebody = response.getBody();
			Map<String, Object> parsedResponseBody = (Map<String, Object>)JSON.deserializeUntyped(responsebody);
			Contact cont = new Contact();
			cont.DummyJSON_Id__c = dummyUserId;
			cont.Email = (String) parsedResponseBody.get('email');
			cont.Phone = (String) parsedResponseBody.get('phone');
			Object birthDateObj = parsedResponseBody.get('birthDate');
			cont.Birthdate = Date.valueOf(String.valueOf(birthDateObj));//this feels like way overkill, but the typical casting did not work. any direction  you could lead me in for this one?
			Map<String, Object> addressMap = (Map<String, Object>) parsedResponseBody.get('address');
			cont.MailingStreet = (String) addressMap.get('address');
			cont.MailingCity = (String) addressMap.get('city');
			cont.MailingPostalCode = (String) addressMap.get('postalCode');
			cont.MailingState = (String) addressMap.get('state');
			cont.MailingCountry = (String) addressMap.get('country');
			upsert cont DummyJSON_Id__c;
		} 
		//insert/update from the JSON response using the external id (dummyUserId)
	}

	/* 
	 * Question 2
     * Transforms a JSON response from the external system https://dummyjson.com/users into a Salesforce Contact object.
     * The method parses the JSON string to extract user details and map them to a Salesforce Contact object.
     * The contact fields populated from the JSON include Email, Phone, Birthdate, and various address-related fields.
     * The method is primarily designed to work in conjunction with callouts that fetch user details from the external system. 
	 * 
	 * Fields from JSON used to populate Salesforce Contact
	 * Fields: Email, Phone, Birthdate, MailingStreet, MailingCity, MailingPostalCode, MailingState, MailingCountry
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String jsonResponse The JSON string from the external system that contains user details.
     * @return Contact The Salesforce Contact object populated with details from the JSON string.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static Contact createContactFromJson(String jsonResponse) {
		// Deserialize the JSON string into map of primitive data types.
		Map<String, Object> mapBody = (Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
		// Create a new contact from the JSON response.
		Contact conFromResponse = new Contact();
		// Set the contact fields from the JSON response.
		conFromResponse.Email = (String) mapBody.get('email');
		conFromResponse.Phone = (String) mapBody.get('phone');
		conFromResponse.DummyJSON_Last_Updated__c = Datetime.now();
		Object birthDateObj = mapBody.get('birthDate');
		conFromResponse.Birthdate = Date.valueOf(String.valueOf(birthDateObj));
		// Deserialize the address from the JSON response.
		Map<String, Object> addressMap = (Map<String, Object>) mapBody.get('address');
		// Set the address fields on the contact.
		conFromResponse.MailingStreet = (String) addressMap.get('address');
		conFromResponse.MailingCity = (String) addressMap.get('city');
		conFromResponse.MailingPostalCode = (String) addressMap.get('postalCode');
		conFromResponse.MailingState = (String) addressMap.get('state');
		conFromResponse.MailingCountry = (String) addressMap.get('country');
		return conFromResponse;
	}

	/* 
	 * Question 3
     * Sends Contact information to an external system https://dummyjson.com/users/add ('DummyJsonUser') to create or update a user based on the provided Salesforce Contact ID.
     * The method prepares a JSON payload with the contact's information and sends it to the 'DummyJsonUser' add endpoint.
     * If the callout is successful (HTTP status code between 200 and 299), the method updates the contact's 'DummyJSON_Last_Updated__c' field in Salesforce to the current time.
	 * Salesforce Contact should be used to generate the JSON payload
	 * Fields: Id, FirstName, LastName, Email, Phone
	 * This callout method should work in triggers
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param contactId The Salesforce Contact ID used to generate the JSON payload for the external system.
     */
	
	public static void postCreateDummyJSONUser(String contactId) {
		// Create HTTP request to send.
		HttpRequest request = new httpRequest();
		// Set the endpoint URL. Use direct URL or for best practices use Named Credential.
		request.setEndpoint('https://dummyjson.com/users/add');
		// Set the HTTP method to POST.
		request.setMethod('POST');
		// Set the body using generateDummyJsonUserPayload method.
		request.setBody(generateDummyJsonUserPayload(contactId));
		// Send the HTTP request and get the response.
		HttpResponse response = new Http().send(request);
		// If the HTTP response code is successful, update the contact.
		if (response.getStatusCode() >= 200 && response.getStatusCode() <= 299){
			Contact newCon = new Contact(Id = contactId);
			newCon.DummyJSON_Last_Updated__c = Datetime.now();
			update newCon;
		} 
	}

	/*
	 * Question 4
     * Generates a JSON payload based on a Salesforce Contact's fields to be sent to an external system https://dummyjson.com/users/add for user creation or update.
     * The method queries a contact from Salesforce based on the provided contactId and maps its fields into a JSON payload.
     * The fields from Salesforce Contact that are transformed into the JSON payload include Id, FirstName, LastName, Email, and Phone.
     * The generated JSON payload can be sent to the external system for various operations like creating or updating a user.
	 * 
	 * Fields from Salesforce Contact used to generate JSON payload:
	 * Fields: Id => salesforceId, FirstName => firstName, LastName => lastName, Email => email, Phone => phone
	 * 
     * Documentation: https://dummyjson.com/docs/users
     * 
     * @param String contactId The Salesforce Contact ID used to fetch the contact's fields and generate the JSON payload.
     * @return String The JSON string payload that represents the Contact's details.
     */
	@TestVisible // Allows test class to see this method. Since it is private, it would not be visible otherwise.
	private static String generateDummyJsonUserPayload(String contactId) {
		// Query the contact to get the field values to generate the JSON payload.
		Contact conFromSF = [SELECT Id, FirstName, LastName, Email, Phone
							 FROM Contact
							 WHERE Id = :contactId
							 LIMIT 1];
		// Create a map of the field values.
		Map<String, Object> mapBody = new Map<String, Object>();
		mapBody.put('salesforceId', conFromSF.Id);
		mapBody.put('firstName', conFromSF.FirstName != null ? conFromSF.FirstName : 'unknown');
		mapBody.put('lastName', conFromSF.LastName != null ? conFromSF.LastName : 'unknown');
		mapBody.put('email', conFromSF.Email != null ? conFromSF.Email : 'unknown');
		mapBody.put('phone', conFromSF.Phone != null ? conFromSF.Phone : 'unknown');
		// Serialize the map into a JSON string.
		String payload = JSON.serialize(mapBody);
		// Make sure to check that required contacts fields have a value. Default the value to unknown if it does not exists.
		// Integration data can change over time. It is a best practice to add safeguards/validation to ensure the integration does not break.

		return payload;
	}
}