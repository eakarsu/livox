package tr.com.eno.livo.plugin.serviceobjects;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.thrift.TException;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import tr.com.eno.aeon.thrift.serviceobjects.ServiceObject;
import tr.com.eno.aeon.thrift.serviceobjects.ServiceObjectConfigurationError;
import tr.com.eno.aeon.thrift.serviceobjects.ServiceObjectNotFoundError;
import tr.com.eno.aeon.thrift.serviceobjects.ServiceObjectOperationFailedError;
import tr.com.eno.aeon.thrift.serviceobjects.ServiceObjectOperationPayload;
import tr.com.eno.aeon.thrift.serviceobjects.ServiceObjectProxyService;
import tr.com.eno.livo.ConfigPool;
import tr.com.eno.livo.ThriftServicesPool;
import tr.com.eno.livo.ThriftServicesPoolException;
import android.content.Context;
import android.util.Log;

public class ServiceObjectsHandler extends CordovaPlugin{
		
	@Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
		 
			final JSONArray arguments=args;
			
		   Context context = this.cordova.getActivity().getApplicationContext();
				
		   final  ConfigPool configPool = ConfigPool.getInstance(context);
			 
		   final ThriftServicesPool pool = new ThriftServicesPool(configPool.getServerAddress(), configPool.getServerPort());
	    	
			if (action.equalsIgnoreCase("listServiceObjects")) {
	        	
	        	cordova.getThreadPool().execute(new Runnable() {
					
					@Override
					public void run() {
					
						try {
							
							Set<ServiceObject> objects = listServiceObjects(pool, configPool);
							
							//Result that will be returning.
							JSONArray result = new JSONArray();
							
							JSONObject jsonObject;
						
							JSONArray jsonArray ;
							
							
							for(ServiceObject obj: objects){
								
								//ServiceObject information as json object.
								jsonObject = new JSONObject();
								
								jsonObject.put("name", obj.getName());
								
								jsonObject.put("type", obj.getType());
								
								jsonArray = new JSONArray();
																
									for( String operation : obj.getOperationNames()){
										
										jsonArray.put(operation);
									}
								
								jsonObject.put("operationNames", jsonArray);
								
								result.put(jsonObject);
							}
							
							callbackContext.success(result);
						
						} catch (JSONException e) {
							callbackContext.error("Json Error:"+e.getMessage());
						}  catch (ThriftServicesPoolException e) {
							callbackContext.error("Couldn't access to server!");
						} catch (TException e) {
							callbackContext.error("Transport problem has been accured!");
						}
					}
				});	                      
	        }
			else if(action.equalsIgnoreCase("getServiceObject")){
				
				cordova.getThreadPool().execute(new Runnable() {
					
					@Override
					public void run() {
						
						try {
							String objectName = arguments.getString(0);
							
							JSONObject config= arguments.getJSONObject(1);
							
							Map<String,String> conf = new HashMap<String, String>();
							
							Iterator<String> iterator = config.keys();
							
							while(iterator.hasNext()){
								
								conf.put(iterator.next(), config.getString(iterator.next()));
							}
							
							ServiceObject serviceObject = getServiceObject(pool, configPool, objectName, conf);
							
							JSONObject result = new JSONObject();
							
							result.put("name", serviceObject.getName());
							
							result.put("type", serviceObject.getType());
							
							JSONArray operationNames = new JSONArray();
							
							for( String operation : serviceObject.getOperationNames()){
								
								operationNames.put(operation);
							}
							
							result.put("operationNames", operationNames);
							
							callbackContext.success(result);
							
						} catch (JSONException e) {
							callbackContext.error("Json Error:"+e.getMessage());
						} catch (ServiceObjectNotFoundError e) {
							callbackContext.error("No such a service!");
						} catch (ServiceObjectConfigurationError e) {
							callbackContext.error("Service configuration error!");
						} catch (ThriftServicesPoolException e) {
							callbackContext.error("Couldn't access to server!");
						} catch (TException e) {
							callbackContext.error("Transport problem has been accured!");
						}
						
					}
				});
			} 
			
			else if(action.equalsIgnoreCase("performOperation")){
				
				cordova.getThreadPool().execute(new Runnable() {
					
					@Override
					public void run() {
	
							
							try {
							String 	operationName = arguments.getString(1);
							
							Log.e("operationName:", operationName);
							
							JSONObject serviceObj = arguments.getJSONObject(0);
							
							Log.e("serviceObject:", serviceObj.toString());
							
							Log.e("arguments:",arguments.toString());
							
							String rawObject= arguments.getString(2);
													
							JSONObject payloadObj=new JSONObject(rawObject);
							
							Log.e("payload:", payloadObj.toString());
							
							Set<String> operationNames = new HashSet<String>();
							
							for(int i=0;i<serviceObj.getJSONArray("operationNames").length();i++){
								
								operationNames.add(serviceObj.getJSONArray("operationNames").getString(i));
								
							}
							
							ServiceObject requestedObj = new ServiceObject(serviceObj.getString("name"),serviceObj.getString("type"), operationNames);
							
							ServiceObjectOperationPayload payload = new ServiceObjectOperationPayload(payloadObj.toString(), "application/json");
							
							ServiceObjectOperationPayload returnPayload = performOperation(pool, configPool, requestedObj, operationName, payload);
							
							Log.e("incoming data:", returnPayload.getContent());
						
							callbackContext.success(new JSONObject(returnPayload.getContent()));
							} catch (JSONException e) {
								Log.e("Json", e.getMessage(), e);
								callbackContext.error("Json Error:"+e.getMessage());
								
							} catch (ServiceObjectOperationFailedError e) {
								Log.e("ServiceObjectOperationFailedError", "Thrift",e);
								callbackContext.error("Operation failed!");
							} catch (ThriftServicesPoolException e) {
								Log.e("ThriftServicesPoolException", e.fillInStackTrace().toString());
								callbackContext.error("Couldn't access to server!");
							} catch (TException e) {
								Log.e("TException", e.fillInStackTrace().toString());
								callbackContext.error("Transport problem has been accured!");
							}
					
					}
				});
				
				
			}
			
			else callbackContext.error("Action: '"+action+"' is not defined!");  
        
        pool.closeTransport();
        return true;
    }
	
	private final Set<ServiceObject> listServiceObjects(ThriftServicesPool pool , ConfigPool configPool) throws ThriftServicesPoolException, TException{
		
		pool.openTransport();
		
		ServiceObjectProxyService.Client client = pool.getServObjProxyService();
		
		Set<ServiceObject>  objects = client.listServiceObjects(configPool.getToken());
		
		pool.closeTransport();
		
		return  objects;
		
	}
	
	private ServiceObject getServiceObject(ThriftServicesPool pool, ConfigPool configPool, String name, Map<String,String> conf) throws ThriftServicesPoolException, ServiceObjectNotFoundError, ServiceObjectConfigurationError, TException{
		
		pool.openTransport();
		
		ServiceObjectProxyService.Client client = pool.getServObjProxyService();
		
		ServiceObject obj = client.getServiceObject(configPool.getToken(), name, conf);
		
		pool.closeTransport();
		
		return obj;
	}
	
	private ServiceObjectOperationPayload performOperation(ThriftServicesPool pool, ConfigPool configPool, ServiceObject obj, String operationName,ServiceObjectOperationPayload payload) throws ThriftServicesPoolException, ServiceObjectOperationFailedError, TException{
		
		pool.openTransport();
		
		ServiceObjectProxyService.Client client = pool.getServObjProxyService();
		
		ServiceObjectOperationPayload rPayload = client.performOperation(configPool.getToken(), obj, operationName, payload);
		
		pool.closeTransport();
		
		return rPayload;
		
	}
}
