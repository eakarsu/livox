package com.livomobile;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URLDecoder;
import java.text.MessageFormat;
import java.text.ParseException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import javax.mail.Message;
import javax.mail.Message.RecipientType;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.IOUtils;
import org.apache.commons.validator.routines.EmailValidator;
import org.mortbay.util.ajax.JSON;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ContactServlet extends HttpServlet {

	private static final long serialVersionUID = -8697187829277152385L;
	private static final Logger LOGGER = LoggerFactory
			.getLogger(ContactServlet.class);
	private static final MessageFormat CONTACT_INPUT_FORMAT = new MessageFormat(
			"inputName={0}&inputEmail={1}&inputMessage={2}");
	private static final int CONTACT_MINIMUM_MESSAGE_SIZE = 5;

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {

		resp.setContentType("application/json");

		Map<String, Object> response = new HashMap<String, Object>();

		String name = null, emailAddress = null, message = null;
		try {

			Object[] parsedObjs = CONTACT_INPUT_FORMAT.parse(IOUtils
					.toString(req.getReader()));

			name = URLDecoder.decode((String) parsedObjs[0], "UTF-8");
			emailAddress = URLDecoder.decode((String) parsedObjs[1], "UTF-8");
			emailAddress = URLDecoder.decode(emailAddress, "UTF-8");
			message = URLDecoder.decode((String) parsedObjs[2], "UTF-8");

		} catch (ParseException e) {

			LOGGER.error(e.getMessage(), e);
			
			response.put("status", false);
			response.put("html", "<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Warning!</strong> Please enter your name</div>");

			resp.getWriter().write(JSON.toString(response));
		}
		
		if (name == null || name.isEmpty() || name.trim().isEmpty()) {
			
			response.put("status", false);
			response.put("html", "<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Warning!</strong> Please enter your name</div>");

		} else if (emailAddress == null || emailAddress.isEmpty() || emailAddress.trim().isEmpty() || !this.isMailAddressValid(emailAddress)) {
			
			response.put("status", false);
			response.put("html", "<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Warning!</strong> Please enter a valid email address</div>");
			
		} else if (message == null || message.length() < CONTACT_MINIMUM_MESSAGE_SIZE) {
			
			response.put("status", false);
			response.put("html", "<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Warning!</strong> Your messages needs to have at least " + CONTACT_MINIMUM_MESSAGE_SIZE + " characters</div>");
			
		} else {
			
			if (this.sendMail(name, emailAddress, message)) {
				
				response.put("status", true);
				response.put("html", "<div class=\"alert alert-success alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Thank you</strong> Your message has been delivered</div>");

			} else {
				
				response.put("status", true);
				response.put("html", "<div class=\"alert alert-warning alert-dismissable\"><button type=\"button\" class=\"close\" data-dismiss=\"alert\" aria-hidden=\"true\">&times;</button><strong>Error!</strong> We encountered an unexpected error and apologize for this inconvenience</div>");
			}
		}

		resp.getWriter().write(JSON.toString(response));
	}

	private boolean sendMail(String name, String emailAddress, String message) {
		
		// Prepate the session
		Session session = Session.getDefaultInstance(new Properties(), null);
		
		try {
			
			// Prepare the message
			Message mailMessage = new MimeMessage(session);
			mailMessage.setFrom(new InternetAddress("info@livomobile.com", "Livomobile.com Administration"));
			mailMessage.setRecipient(RecipientType.TO, new InternetAddress("info@eno.com.tr"));
			mailMessage.setSubject(MessageFormat.format("Contact from Livomobile.com by {0} <{1}>", name, emailAddress));
			mailMessage.setText(message);
			
			// Send the message
			Transport.send(mailMessage);
			
		} catch (UnsupportedEncodingException e) {

			LOGGER.error(e.getMessage(), e);
			return false;
			
		} catch (MessagingException e) {

			LOGGER.error(e.getMessage(), e);
			return false;
		}
		
		return true;
	}

	private boolean isMailAddressValid(String emailAddress) {

		return EmailValidator.getInstance().isValid(emailAddress);
	}
}
