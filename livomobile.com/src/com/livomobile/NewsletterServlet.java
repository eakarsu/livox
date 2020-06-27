package com.livomobile;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.Charset;
import java.text.MessageFormat;
import java.text.ParseException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.IOUtils;
import org.apache.commons.validator.routines.EmailValidator;
import org.mortbay.util.ajax.JSON;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.appengine.labs.repackaged.org.json.JSONArray;
import com.google.appengine.labs.repackaged.org.json.JSONException;
import com.google.appengine.labs.repackaged.org.json.JSONObject;

public class NewsletterServlet extends HttpServlet {

	private static final long serialVersionUID = 6544441650307690678L;
	private static final Logger LOGGER = LoggerFactory
			.getLogger(NewsletterServlet.class);
	// private static final MailChimpClient MAILCHIMP_CLIENT = new
	// MailChimpClient();
	private static final String MAILCHIMP_API_KEY = "8f1c5664b7b02ee0cc90f881a3dd2e70-us10";
	private static final String MAILCHIMP_LIST_ID = "b83f5af934";
	private static final MessageFormat NEWSLETTER_INPUT_FORMAT = new MessageFormat(
			"emailInputNewsletter={0}");
	private static final String MAILCHIMP_SUBSCRIBE_URL = "https://us8.api.mailchimp.com/2.0/lists/subscribe.json";
	private static final String MAILCHIMP_MEMBER_INFO_URL = "https://us8.api.mailchimp.com/2.0/lists/member-info.json";

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {

		String emailAddress = null;
		try {

			emailAddress = (String) NEWSLETTER_INPUT_FORMAT.parse(IOUtils
					.toString(req.getReader()))[0];
			emailAddress = URLDecoder.decode(emailAddress, "UTF-8");

		} catch (ParseException e) {

			LOGGER.error(e.getMessage(), e);
		}

		LOGGER.debug(
				"Received a request to subscribe e-mail address '{}' to the newsletter.",
				emailAddress);

		resp.setContentType("application/json");

		Map<String, Object> response = new HashMap<String, Object>();

		if (emailAddress == null || emailAddress.isEmpty()
				|| emailAddress.trim().isEmpty()) {

			response.put("status", false);
			response.put(
					"html",
					"<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Warning!</strong> Please enter your email address</div>");

		} else if (!this.isMailAddressValid(emailAddress)) {

			response.put("status", false);
			response.put(
					"html",
					"<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Warning!</strong> Please enter a valid email address</div>");

		} else {

			if (this.subscribeMailAddress(emailAddress)) {

				response.put("status", true);
				response.put(
						"html",
						"<div class=\"alert alert-success alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Thank you</strong> Your message has been delivered</div>");
			} else {

				response.put("status", false);
				response.put(
						"html",
						"<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Error!</strong> We encountered an unexpected error and apologize for this inconvenience</div>");
			}
		}

		resp.getWriter().write(JSON.toString(response));
	}

	private boolean isMailAddressValid(String emailAddress) {

		return EmailValidator.getInstance().isValid(emailAddress);
	}

	private boolean subscribeMailAddress(String emailAddress) {

		try {
			
			// Prepare the JSON request payload
			JSONObject requestPayload = new JSONObject();
			requestPayload.put("apikey", MAILCHIMP_API_KEY);
			requestPayload.put("id", MAILCHIMP_LIST_ID);
			requestPayload.put("email", new JSONObject(Collections.singletonMap("email", emailAddress)));
			requestPayload.put("double_optin", false);
			requestPayload.put("update_existing", true);
			requestPayload.put("send_welcome", true);

			// Prepare the URL connection
			HttpURLConnection subscribeConnection = (HttpURLConnection) new URL(MAILCHIMP_SUBSCRIBE_URL)
					.openConnection();
			subscribeConnection.setDoOutput(true);
			subscribeConnection.setRequestProperty("Content-Type", "application/json");
			subscribeConnection.setConnectTimeout(12000);
			
			// Write the request payload
			subscribeConnection.getOutputStream().write(requestPayload.toString().getBytes(Charset.forName("UTF-8")));

			// If this operation is not successful, report the error.
			if (subscribeConnection.getResponseCode() != 200) {
				
				LOGGER.error("Subscription operation is failed with status code {} and message '{}'.", subscribeConnection.getResponseCode(), subscribeConnection.getResponseMessage());
				
				if (subscribeConnection.getErrorStream() != null)
					LOGGER.error("Content of the failed operation response is '{}'.", IOUtils.toString(subscribeConnection.getErrorStream()));
				
				return false;
			}

		} catch (MalformedURLException e) {

			LOGGER.error(e.getMessage(), e);
			return false;

		} catch (IOException e) {

			LOGGER.warn(
					"Encountered an IO error while subscribing the e-mail '{}' to the newsletter.",
					emailAddress);
			LOGGER.error(e.getMessage(), e);
			return false;
			
		} catch (JSONException e) {

			LOGGER.error(e.getMessage(), e);
			return false;
		}
		
		/*try {
			
			// Prepare the JSON request payload
			JSONObject requestPayload = new JSONObject();
			requestPayload.put("apikey", MAILCHIMP_API_KEY);
			requestPayload.put("id", MAILCHIMP_LIST_ID);
			requestPayload.put("emails", new JSONArray(new JSONObject(Collections.singletonMap("email", emailAddress))));

			// Prepare the URL connection
			HttpURLConnection memberInfoConnection = (HttpURLConnection) new URL(MAILCHIMP_MEMBER_INFO_URL)
					.openConnection();
			memberInfoConnection.setDoOutput(true);
			memberInfoConnection.setRequestProperty("Content-Type", "application/json");
			memberInfoConnection.setConnectTimeout(12000);
			
			// Write the request payload
			memberInfoConnection.getOutputStream().write(requestPayload.toString().getBytes(Charset.forName("UTF-8")));

			// If this operation is not successful, report the error.
			if (memberInfoConnection.getResponseCode() != 200) {
				
				LOGGER.error("Membership information fetch operation is failed with status code {} and message '{}'.", memberInfoConnection.getResponseCode(), memberInfoConnection.getResponseMessage());
				
				if (memberInfoConnection.getErrorStream() != null)
					LOGGER.error("Content of the failed operation response is '{}'.", IOUtils.toString(memberInfoConnection.getErrorStream()));
				
				return false;
			}
			
			// Get the email status
			JSONObject result = new JSONObject(IOUtils.toString(memberInfoConnection.getInputStream()));
			JSONObject data = (JSONObject) ((JSONArray) result.get("data")).get(0);
			
			// Check the status
			String status = (String) data.get("status");
			if (!(status.equalsIgnoreCase("pending") || status.equalsIgnoreCase("subscribed"))) {
				
				LOGGER.info("Newsletter subscription of e-mail address '{}' failed with status '{}'.", emailAddress, status);
				return false;
			}

		} catch (MalformedURLException e) {

			LOGGER.error(e.getMessage(), e);
			return false;

		} catch (IOException e) {

			LOGGER.warn(
					"Encountered an IO error while fetching membership information for the e-mail '{}' to the newsletter.",
					emailAddress);
			LOGGER.error(e.getMessage(), e);
			return false;
			
		} catch (JSONException e) {

			LOGGER.error(e.getMessage(), e);
			return false;
		}*/
		
		LOGGER.info("E-mail address '{}' successfully subscribed to the newsletter.", emailAddress);
		
		return true;
	}
}
